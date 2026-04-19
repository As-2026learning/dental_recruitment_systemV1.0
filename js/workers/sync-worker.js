/**
 * 数据同步Worker
 * 在后台线程执行数据同步，不阻塞主线程
 * fix: 解决看板加载时间过长问题 - 将同步逻辑移至Worker线程
 */

// Worker内部引入Supabase客户端
importScripts('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js');

// Supabase配置
let supabaseClient = null;
let isCancelled = false;

/**
 * 初始化Supabase客户端
 */
function initSupabase(url, key) {
    try {
        supabaseClient = supabase.createClient(url, key);
        self.postMessage({ type: 'INIT_COMPLETE' });
    } catch (error) {
        self.postMessage({ 
            type: 'INIT_ERROR', 
            payload: { error: error.message } 
        });
    }
}

/**
 * 主消息处理器
 */
self.onmessage = async function(e) {
    const { type, payload } = e.data;
    
    switch(type) {
        case 'INIT':
            // 初始化配置
            initSupabase(payload.url, payload.key);
            break;
            
        case 'SYNC':
            // 执行同步
            isCancelled = false;
            try {
                const result = await performSync(payload);
                self.postMessage({ 
                    type: 'SYNC_COMPLETE', 
                    payload: result 
                });
            } catch (error) {
                self.postMessage({ 
                    type: 'SYNC_ERROR', 
                    payload: { error: error.message } 
                });
            }
            break;
            
        case 'CANCEL':
            // 取消同步
            isCancelled = true;
            self.postMessage({ type: 'CANCELLED' });
            break;
    }
};

/**
 * 执行同步主逻辑
 * fix: 分批处理数据，定期发送进度消息
 */
async function performSync(params) {
    const { forceFull, lastSyncTime } = params;
    
    // 发送进度：开始
    self.postMessage({ 
        type: 'PROGRESS', 
        payload: { stage: 'START', percent: 0, message: '开始同步...' } 
    });
    
    try {
        // 1. 检查是否需要全量同步
        const needFullSync = forceFull || !lastSyncTime;
        
        // 2. 查询applications表
        self.postMessage({ 
            type: 'PROGRESS', 
            payload: { stage: 'FETCHING', percent: 5, message: '查询应聘数据...' } 
        });
        
        let appQuery = supabaseClient.from('applications').select('*');
        if (!needFullSync && lastSyncTime) {
            appQuery = appQuery.gt('updated_at', lastSyncTime);
        }
        
        const { data: applications, error: appError } = await appQuery
            .order('created_at', { ascending: false });
        
        if (appError) throw appError;
        
        // 如果没有新数据，直接返回
        if (!applications || applications.length === 0) {
            return { 
                success: true, 
                message: '没有需要同步的新数据', 
                count: 0, 
                inserted: 0, 
                updated: 0 
            };
        }
        
        // 3. 并行查询bookings和recruitment_process
        self.postMessage({ 
            type: 'PROGRESS', 
            payload: { stage: 'FETCHING', percent: 15, message: '查询关联数据...' } 
        });
        
        const [bookingsResult, rpResult] = await Promise.all([
            supabaseClient.from('bookings').select('id, application_id, status'),
            supabaseClient.from('recruitment_process').select('id, application_id, name, phone, id_card, source_status, current_stage, current_status, updated_at, first_interview_result, second_interview_result, accept_offer, hire_department, hire_position, first_interview_time, first_interviewer, first_reject_reason, second_interview_time, second_interviewer, second_reject_reason')
        ]);
        
        const { data: bookings } = bookingsResult;
        const { data: existingRpData } = rpResult;
        
        // 4. 过滤有效数据（排除已取消、已拒绝）
        self.postMessage({ 
            type: 'PROGRESS', 
            payload: { stage: 'FILTERING', percent: 20, message: '过滤数据...' } 
        });
        
        const validApplications = filterValidApplications(applications);
        
        // 5. 构建映射表
        const bookingStatusMap = new Map();
        (bookings || []).forEach(booking => {
            if (booking.application_id) {
                bookingStatusMap.set(String(booking.application_id), booking.status);
            }
        });
        
        const rpDataMap = new Map();
        const existingAppMap = new Map();
        const existingUniqueKeyMap = new Map();
        
        (existingRpData || []).forEach(rp => {
            if (rp.application_id) {
                const appIdStr = String(rp.application_id);
                rpDataMap.set(appIdStr, rp);
                existingAppMap.set(appIdStr, rp);
            }
            
            // 构建唯一标识映射
            if (rp.name) {
                const phone = rp.phone || '';
                const idCard = rp.id_card || '';
                
                if (phone && phone.length >= 7) {
                    const uniqueKey = `${rp.name.trim().toLowerCase()}_${phone}`;
                    existingUniqueKeyMap.set(uniqueKey, rp);
                } else if (idCard && idCard.length >= 15) {
                    const uniqueKey = `${rp.name.trim().toLowerCase()}_${idCard}`;
                    existingUniqueKeyMap.set(uniqueKey, rp);
                }
            }
        });
        
        // 6. 分批处理数据
        self.postMessage({ 
            type: 'PROGRESS', 
            payload: { 
                stage: 'PROCESSING', 
                percent: 25, 
                message: `处理数据: 0/${validApplications.length}` 
            } 
        });
        
        const newRecords = [];
        const updateRecords = [];
        const total = validApplications.length;
        const batchSize = 50;
        
        for (let i = 0; i < total; i += batchSize) {
            // 检查是否取消
            if (isCancelled) {
                throw new Error('同步已取消');
            }
            
            const batch = validApplications.slice(i, i + batchSize);
            
            // 处理批次
            for (const app of batch) {
                const result = processApplication(app, {
                    rpDataMap,
                    existingAppMap,
                    existingUniqueKeyMap,
                    bookingStatusMap
                });
                
                if (result.type === 'NEW') {
                    newRecords.push(result.data);
                } else if (result.type === 'UPDATE') {
                    updateRecords.push(result.data);
                }
            }
            
            // 发送进度
            const percent = 25 + Math.floor((i + batch.length) / total * 45);
            self.postMessage({ 
                type: 'PROGRESS', 
                payload: { 
                    stage: 'PROCESSING', 
                    percent,
                    message: `处理数据: ${Math.min(i + batch.length, total)}/${total}`
                } 
            });
        }
        
        // 7. 批量插入新记录
        let insertedCount = 0;
        if (newRecords.length > 0) {
            self.postMessage({ 
                type: 'PROGRESS', 
                payload: { 
                    stage: 'INSERTING', 
                    percent: 70, 
                    message: `插入新记录: ${newRecords.length}条...` 
                } 
            });
            
            const validatedRecords = validateRecords(newRecords);
            
            const { data: inserted, error: insertError } = await supabaseClient
                .from('recruitment_process')
                .insert(validatedRecords)
                .select();
            
            if (insertError) {
                console.error('插入失败:', insertError);
            } else {
                insertedCount = inserted ? inserted.length : 0;
            }
        }
        
        // 8. 批量更新记录
        let updatedCount = 0;
        if (updateRecords.length > 0) {
            self.postMessage({ 
                type: 'PROGRESS', 
                payload: { 
                    stage: 'UPDATING', 
                    percent: 85, 
                    message: `更新记录: ${updateRecords.length}条...` 
                } 
            });
            
            // 并行更新
            const updatePromises = updateRecords.map(async (record) => {
                try {
                    const { id, application_id, ...fieldsToUpdate } = record;
                    const validatedRecord = validateRecord(fieldsToUpdate);
                    
                    const { error } = await supabaseClient
                        .from('recruitment_process')
                        .update(validatedRecord)
                        .eq('id', id);
                    
                    return { success: !error };
                } catch (err) {
                    return { success: false };
                }
            });
            
            const results = await Promise.all(updatePromises);
            updatedCount = results.filter(r => r.success).length;
        }
        
        // 9. 完成
        self.postMessage({ 
            type: 'PROGRESS', 
            payload: { stage: 'COMPLETE', percent: 100, message: '同步完成' } 
        });
        
        return {
            success: true,
            message: `同步完成：新增 ${insertedCount} 条，更新 ${updatedCount} 条`,
            count: total,
            inserted: insertedCount,
            updated: updatedCount
        };
        
    } catch (error) {
        console.error('同步失败:', error);
        throw error;
    }
}

/**
 * 过滤有效应聘记录（排除已取消、已拒绝）
 */
function filterValidApplications(applications) {
    return applications.filter(app => {
        let appStatus = app.status || '';
        
        // 从dynamic_fields中获取状态
        if (!appStatus) {
            const dynamicFields = app.form_data || app.fields || app.dynamic_fields || {};
            const statusFields = ['status', '应聘状态', '申请状态', 'state'];
            for (const field of statusFields) {
                if (dynamicFields[field]) {
                    appStatus = dynamicFields[field];
                    break;
                }
            }
        }
        
        const isCancelled =
            appStatus === '已取消' || appStatus === 'cancelled' || appStatus === 'canceled' ||
            appStatus === 'cancel' || appStatus === '已撤销' || appStatus === '撤销';
        const isRejected =
            appStatus === '已拒绝' || appStatus === 'rejected' || appStatus === 'reject' ||
            appStatus === '拒绝' || appStatus === '不通过' || appStatus === '未通过';
        
        return !(isCancelled || isRejected);
    });
}

/**
 * 处理单条应聘记录
 */
function processApplication(app, maps) {
    const { rpDataMap, existingAppMap, existingUniqueKeyMap, bookingStatusMap } = maps;
    
    if (!app.id) {
        return { type: 'SKIP' };
    }
    
    const appIdStr = String(app.id);
    const dynamicFields = app.dynamic_fields || app.form_data || app.fields || {};
    
    // 提取字段
    const getFieldValue = (fieldNames) => {
        for (const name of fieldNames) {
            if (dynamicFields[name] !== undefined && dynamicFields[name] !== null && dynamicFields[name] !== '') {
                return dynamicFields[name];
            }
            if (app[name] !== undefined && app[name] !== null && app[name] !== '') {
                return app[name];
            }
        }
        return null;
    };
    
    const idCard = app.id_card || app.form_data?.id_card || app.dynamic_fields?.id_card ||
        getFieldValue(['id_card', '身份证', '身份证号', '身份证号码']);
    const jobType = getFieldValue(['job_type', '工种', '职位类型']);
    const skills = getFieldValue(['skills', '技能', '专业技能']);
    const experience = app.experience || getFieldValue(['experience', '工作年限', '相关工作经验']);
    const sourceChannel = getFieldValue(['source_channel', 'channel', '招聘渠道', '渠道']);
    
    // 合并recruitment_process数据
    const rpData = rpDataMap.get(appIdStr);
    if (rpData) {
        if (rpData.first_interview_time) app.first_interview_time = rpData.first_interview_time;
        if (rpData.first_interviewer) app.first_interviewer = rpData.first_interviewer;
        if (rpData.first_interview_result) app.first_interview_result = rpData.first_interview_result;
        if (rpData.second_interview_time) app.second_interview_time = rpData.second_interview_time;
        if (rpData.second_interviewer) app.second_interviewer = rpData.second_interviewer;
        if (rpData.second_interview_result) app.second_interview_result = rpData.second_interview_result;
        if (rpData.current_stage) app.current_stage = rpData.current_stage;
        if (rpData.current_status) app.current_status = rpData.current_status;
        if (rpData.accept_offer) app.accept_offer = rpData.accept_offer;
        if (rpData.hire_department) app.hire_department = rpData.hire_department;
        if (rpData.hire_position) app.hire_position = rpData.hire_position;
    }
    
    // 检查是否已存在
    let existingRecord = existingAppMap.get(appIdStr);
    
    if (!existingRecord && app.name) {
        const appPhone = (app.phone || '').trim();
        const appIdCard = (idCard || '').trim();
        
        let uniqueKey = null;
        if (appPhone && appPhone.length >= 7) {
            uniqueKey = `${app.name.trim().toLowerCase()}_${appPhone}`;
        } else if (appIdCard && appIdCard.length >= 15) {
            uniqueKey = `${app.name.trim().toLowerCase()}_${appIdCard}`;
        }
        
        if (uniqueKey && existingUniqueKeyMap.has(uniqueKey)) {
            existingRecord = existingUniqueKeyMap.get(uniqueKey);
        }
    }
    
    // 确定阶段
    const stageInfo = determineStage(app);
    
    // 获取source_status
    const sourceStatus = app.status || dynamicFields.status || dynamicFields['应聘状态'] || 'pending';
    
    if (existingRecord) {
        // 更新记录
        const updateData = { id: existingRecord.id };
        let needUpdate = false;
        
        if (jobType && jobType !== existingRecord.job_type) {
            updateData.job_type = jobType;
            needUpdate = true;
        }
        if (idCard && idCard !== existingRecord.id_card) {
            updateData.id_card = idCard;
            needUpdate = true;
        }
        if (sourceStatus !== existingRecord.source_status) {
            updateData.source_status = sourceStatus;
            needUpdate = true;
        }
        
        // 只有未处理记录才更新阶段
        const hasProcessed = existingRecord.first_interview_result || 
                            existingRecord.second_interview_result ||
                            existingRecord.current_stage !== 'application';
        
        if (!hasProcessed) {
            if (stageInfo.stage !== existingRecord.current_stage) {
                updateData.current_stage = stageInfo.stage;
                needUpdate = true;
            }
            if (stageInfo.status !== existingRecord.current_status) {
                updateData.current_status = stageInfo.status;
                needUpdate = true;
            }
        }
        
        if (needUpdate) {
            return { type: 'UPDATE', data: updateData };
        }
    } else {
        // 新记录
        return {
            type: 'NEW',
            data: {
                application_id: app.id,
                name: app.name,
                gender: app.gender,
                phone: app.phone,
                age: app.age,
                id_card: idCard,
                email: app.email,
                position: app.position,
                job_type: jobType,
                education: app.education,
                experience: experience,
                skills: skills,
                source_channel: sourceChannel,
                source_status: sourceStatus,
                current_stage: stageInfo.stage,
                current_status: stageInfo.status,
                first_interview_time: app.first_interview_time,
                first_interviewer: app.first_interviewer,
                first_interview_result: app.first_interview_result,
                second_interview_time: app.second_interview_time,
                second_interviewer: app.second_interviewer,
                second_interview_result: app.second_interview_result,
                accept_offer: app.accept_offer,
                hire_department: app.hire_department,
                hire_position: app.hire_position,
                created_at: app.created_at,
                updated_at: app.updated_at
            }
        };
    }
    
    return { type: 'SKIP' };
}

/**
 * 根据数据确定招聘阶段
 */
function determineStage(app) {
    // 已报到
    const isReported = app.is_reported === true || app.is_reported === 'true' || 
                      app.is_reported === 1 || app.is_reported === '1' || app.is_reported === 'yes';
    const hasNoReportReason = app.no_report_reason && app.no_report_reason.trim() !== '' && app.no_report_reason !== '无';
    
    if ((isReported || app.current_stage === 'onboarded') && !hasNoReportReason) {
        return { stage: 'onboarded', status: 'completed' };
    }
    
    // 未报到/待报到
    if (hasNoReportReason) {
        return { stage: 'hired', status: 'pending' };
    }
    
    // 录用阶段
    const acceptOfferValue = app.accept_offer;
    const hasAcceptedOffer = acceptOfferValue === 'yes' || acceptOfferValue === '是' || 
                            acceptOfferValue === true || acceptOfferValue === 1 || acceptOfferValue === '1';
    
    if (hasAcceptedOffer || app.hire_department || app.hire_position || app.current_stage === 'hired') {
        if (acceptOfferValue === 'no' || acceptOfferValue === '否') {
            return { stage: 'hired', status: 'rejected' };
        }
        return { stage: 'hired', status: 'pending' };
    }
    
    // 复试阶段
    if (app.second_interview_result) {
        if (app.second_interview_result === 'pass') return { stage: 'second_interview', status: 'passed' };
        if (app.second_interview_result === 'reject') return { stage: 'second_interview', status: 'reject' };
        return { stage: 'second_interview', status: 'pending' };
    }
    
    if (app.second_interview_time || app.second_interviewer) {
        return { stage: 'second_interview', status: 'pending' };
    }
    
    // 初试阶段
    if (app.first_interview_result) {
        if (app.first_interview_result === 'pass') return { stage: 'first_interview', status: 'passed' };
        if (app.first_interview_result === 'reject') return { stage: 'first_interview', status: 'reject' };
        return { stage: 'first_interview', status: 'pending' };
    }
    
    if (app.first_interview_time || app.first_interviewer) {
        return { stage: 'first_interview', status: 'pending' };
    }
    
    // 默认：投递简历
    return { stage: 'application', status: 'pending' };
}

/**
 * 验证记录字段长度
 */
function validateRecords(records) {
    const MAX_LENGTHS = {
        source_status: 50,
        source_channel: 50,
        name: 100,
        phone: 20,
        position: 100,
        job_type: 50,
        id_card: 18,
        email: 100
    };
    
    return records.map(record => {
        const validated = { ...record };
        Object.entries(MAX_LENGTHS).forEach(([field, maxLength]) => {
            if (validated[field] && typeof validated[field] === 'string' && validated[field].length > maxLength) {
                validated[field] = validated[field].substring(0, maxLength);
            }
        });
        return validated;
    });
}

/**
 * 验证单条记录
 */
function validateRecord(record) {
    const MAX_LENGTHS = {
        source_status: 50,
        source_channel: 50,
        name: 100,
        phone: 20,
        position: 100,
        job_type: 50,
        id_card: 18,
        email: 100
    };
    
    const validated = { ...record };
    Object.entries(MAX_LENGTHS).forEach(([field, maxLength]) => {
        if (validated[field] && typeof validated[field] === 'string' && validated[field].length > maxLength) {
            validated[field] = validated[field].substring(0, maxLength);
        }
    });
    return validated;
}
