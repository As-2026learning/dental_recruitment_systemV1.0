/**
 * 招聘流程管理模块 - 主页面逻辑
 */

// fix: 使用CONFIG对象替代硬编码的Supabase配置 - 解决安全红线问题
const RECRUITMENT_SUPABASE_URL = (typeof CONFIG !== 'undefined') ? CONFIG.SUPABASE_URL : 'https://your-project.supabase.co';
const RECRUITMENT_SUPABASE_KEY = (typeof CONFIG !== 'undefined') ? CONFIG.SUPABASE_KEY : 'your-anon-key';

// 初始化Supabase客户端
const recruitmentSupabase = window.supabase.createClient(RECRUITMENT_SUPABASE_URL, RECRUITMENT_SUPABASE_KEY);

// 全局变量
let dataManager;
let table;
let detailModal;
let firstInterviewModal;
let secondInterviewModal;
let onboardingModal;
let exportManager;
let dataQualityChecker;
let interviewDateSyncService;

// 初始化
document.addEventListener('DOMContentLoaded', async () => {
    initComponents();
    bindEvents();
    // 优化：同步面试日期和加载数据并行执行
    await Promise.all([
        syncInterviewDates(),
        loadData()
    ]);
});

/**
 * 初始化组件
 */
function initComponents() {
    dataManager = new RecruitmentDataManager(recruitmentSupabase);
    exportManager = new ExportManager(EXPORT_FIELDS);
    dataQualityChecker = new DataQualityChecker(dataManager);
    
    // 面试日期同步服务
    interviewDateSyncService = new InterviewDateSyncService(recruitmentSupabase);
    
    // 初始化表格
    table = new DynamicTable('tableContainer', {
        fields: CORE_FIELDS,
        showCheckbox: true,
        onRowClick: (id) => showDetail(id),
        onView: (id) => showDetail(id),
        onProcess: (id, stage) => handleProcess(id, stage),
        onSelectionChange: (selectedIds) => {
            console.log('选中记录:', selectedIds);
            updateBatchDeleteButton(selectedIds);
        }
    });

    // 初始化弹窗
    detailModal = new DetailModal();
    firstInterviewModal = new FirstInterviewModal();
    secondInterviewModal = new SecondInterviewModal();
    onboardingModal = new OnboardingModal();
}

/**
 * 加载数据
 * 优化：先加载数据显示，再后台同步
 */
async function loadData() {
    showLoading();

    // 优化：先加载数据，快速显示页面
    const result = await dataManager.loadData();

    if (result.success) {
        updateStats();
        updateFilterOptions();
        renderTable();
        updatePagination();

        // 优化：数据加载完成后再后台同步（不阻塞页面显示）
        // 使用 setTimeout 让同步在页面渲染后执行
        setTimeout(async () => {
            const syncResult = await dataManager.syncFromApplications();
            if (syncResult.success && syncResult.count > 0) {
                console.log(syncResult.message);
                // 同步完成后刷新数据
                await dataManager.loadData();
                renderTable();
                updatePagination();
            }
        }, 100);
    } else {
        showError('加载数据失败: ' + result.error);
    }

    hideLoading();
}

/**
 * 显示加载状态
 */
function showLoading() {
    document.getElementById('tableContainer').innerHTML = '<div class="loading-message">正在加载数据...</div>';
}

/**
 * 隐藏加载状态
 */
function hideLoading() {
    // 加载完成后会自动渲染表格
}

/**
 * 显示错误信息
 */
function showError(message) {
    document.getElementById('tableContainer').innerHTML = `<div class="empty-message" style="color: #ff4d4f;">${message}</div>`;
}

/**
 * 更新统计信息
 */
function updateStats() {
    const stats = dataManager.getStatistics();
    const statsContainer = document.getElementById('statsCards');

    statsContainer.innerHTML = `
        <div class="stat-card" data-filter="all" title="点击查看全部候选人">
            <div class="stat-value">${stats.total}</div>
            <div class="stat-label">总应聘人数</div>
        </div>
        <div class="stat-card" data-filter="first_interview_pending" title="点击查看初试候选人">
            <div class="stat-value">${stats.firstInterviewPending}</div>
            <div class="stat-label">初试</div>
        </div>
        <div class="stat-card" data-filter="second_interview_pending" title="点击查看复试候选人">
            <div class="stat-value">${stats.secondInterviewPending}</div>
            <div class="stat-label">复试</div>
        </div>
        <div class="stat-card" data-filter="hire_pending" title="点击查看已录用候选人">
            <div class="stat-value">${stats.hirePending}</div>
            <div class="stat-label">录用</div>
        </div>
        <div class="stat-card" data-filter="awaiting_onboard" title="点击查看待报到候选人">
            <div class="stat-value">${stats.awaitingOnboard}</div>
            <div class="stat-label">待报到</div>
        </div>
        <div class="stat-card" data-filter="not_reported" title="点击查看未报到候选人">
            <div class="stat-value">${stats.notReported || 0}</div>
            <div class="stat-label">未报到</div>
        </div>
        <div class="stat-card highlight" data-filter="onboarded" title="点击查看已报到候选人">
            <div class="stat-value">${stats.onboarded}</div>
            <div class="stat-label">已报到</div>
        </div>
    `;

    // 绑定点击事件
    statsContainer.querySelectorAll('.stat-card').forEach(card => {
        card.addEventListener('click', () => {
            const filterType = card.dataset.filter;
            handleStatCardClick(filterType);
        });
    });
}

/**
 * 处理统计卡片点击
 */
function handleStatCardClick(filterType) {
    // 重置所有筛选条件
    document.getElementById('filterPosition').value = '';
    document.getElementById('filterJobType').value = '';
    document.getElementById('filterStage').value = '';
    document.getElementById('filterStatus').value = '';
    // 重置面试日期范围筛选
    document.getElementById('filterStartDate').value = '';
    document.getElementById('filterEndDate').value = '';
    updateDateRangeUI();
    document.getElementById('filterTimeSlot').value = '';
    document.getElementById('filterSearch').value = '';

    // 构建筛选条件
    let filters = {};

    switch (filterType) {
        case 'all':
            // 显示全部，不需要额外筛选
            filters = {};
            break;
        case 'first_interview_pending':
            // 关键修复：初试统计包含所有已完成初试的人（包括已进入复试、录用等后续环节）
            filters = { special_status: 'first_interview_all' };
            document.getElementById('filterStage').value = '';
            document.getElementById('filterStatus').value = '';
            break;
        case 'second_interview_pending':
            // 关键修复：复试统计包含所有已完成复试的人（包括已进入录用等后续环节）
            filters = { special_status: 'second_interview_all' };
            document.getElementById('filterStage').value = '';
            document.getElementById('filterStatus').value = '';
            break;
        case 'hire_pending':
            // 显示所有已录用的人（包括待确认offer、待报到、未报到、已报到）
            filters = { special_status: 'hire_all' };
            document.getElementById('filterStage').value = '';
            break;
        case 'awaiting_onboard':
            // 显示待报到的候选人（current_stage='hired' 且 accept_offer='yes' 且未报到且无未报到原因）
            filters = { special_status: 'awaiting_onboard' };
            document.getElementById('filterStage').value = 'hired';
            document.getElementById('filterStatus').value = 'pending';
            break;
        case 'not_reported':
            // 显示未报到的候选人（current_stage='hired' 且 accept_offer='yes' 且有未报到原因）
            filters = { special_status: 'not_reported' };
            document.getElementById('filterStage').value = 'hired';
            document.getElementById('filterStatus').value = 'reject';
            break;
        case 'onboarded':
            // 显示已报到的候选人（is_reported='yes'）
            filters = { special_status: 'onboarded' };
            document.getElementById('filterStage').value = 'onboarded';
            break;
    }

    // 应用筛选（当选择"全部"时，重置所有筛选条件）
    const shouldReset = filterType === 'all';
    dataManager.applyFilters(filters, shouldReset);
    renderTable();
    updatePagination();

    // 显示提示
    const filterNames = {
        'all': '全部候选人',
        'first_interview_pending': '初试候选人（含后续环节）',
        'second_interview_pending': '复试候选人（含后续环节）',
        'hire_pending': '已录用候选人（含待报到、未报到、已报到）',
        'awaiting_onboard': '待报到候选人',
        'not_reported': '未报到候选人',
        'onboarded': '已报到候选人'
    };

    // 高亮选中的卡片
    document.querySelectorAll('.stat-card').forEach(card => {
        card.classList.remove('active');
    });
    document.querySelector(`.stat-card[data-filter="${filterType}"]`)?.classList.add('active');

    console.log(`已筛选：${filterNames[filterType]}`);

    // 显示清除筛选按钮
    document.getElementById('btnClearFilter').style.display = 'inline-block';
}

/**
 * 清除统计卡片筛选
 */
function clearStatFilter() {
    // 重置所有筛选条件
    document.getElementById('filterPosition').value = '';
    document.getElementById('filterJobType').value = '';
    document.getElementById('filterStage').value = '';
    document.getElementById('filterStatus').value = '';
    // 重置面试日期范围筛选
    document.getElementById('filterStartDate').value = '';
    document.getElementById('filterEndDate').value = '';
    updateDateRangeUI();
    document.getElementById('filterTimeSlot').value = '';
    document.getElementById('filterSearch').value = '';

    // 清除高亮
    document.querySelectorAll('.stat-card').forEach(card => {
        card.classList.remove('active');
    });

    // 隐藏清除筛选按钮
    document.getElementById('btnClearFilter').style.display = 'none';

    // 重新加载数据（重置筛选）
    resetFilters();
}

/**
 * 更新筛选选项
 */
function updateFilterOptions() {
    const options = dataManager.getFilterOptions();

    // 更新岗位选项
    const positionSelect = document.getElementById('filterPosition');
    positionSelect.innerHTML = '<option value="">全部岗位</option>' +
        options.positions.map(pos => `<option value="${pos}">${pos}</option>`).join('');

    // 更新工种选项
    const jobTypeSelect = document.getElementById('filterJobType');
    jobTypeSelect.innerHTML = '<option value="">全部工种</option>' +
        options.jobTypes.map(type => `<option value="${type}">${type}</option>`).join('');
}

/**
 * 同步面试日期
 * 从bookings表同步到recruitment_process和applications表
 * 优化：使用并行更新代替串行更新
 */
async function syncInterviewDates() {
    try {
        console.log('开始同步面试日期...');

        // 获取所有有效的预约记录
        const { data: bookings, error } = await recruitmentSupabase
            .from('bookings')
            .select('application_id, booking_date, time_slot, status')
            .neq('status', 'cancelled')
            .order('created_at', { ascending: false });

        if (error) throw error;

        if (!bookings || bookings.length === 0) {
            console.log('没有需要同步的预约数据');
            return { success: true, message: '没有需要同步的预约数据', count: 0 };
        }

        // 去重 - 只保留每个application_id最新的记录
        const uniqueBookings = [];
        const seenAppIds = new Set();

        for (const booking of bookings) {
            if (!seenAppIds.has(booking.application_id)) {
                uniqueBookings.push(booking);
                seenAppIds.add(booking.application_id);
            }
        }

        console.log(`找到 ${uniqueBookings.length} 条唯一预约记录需要同步`);

        // 优化：并行更新所有记录，而不是串行更新
        const updatePromises = uniqueBookings.map(async (booking) => {
            try {
                // 并行更新recruitment_process表和applications表
                const [rpResult, appResult] = await Promise.all([
                    recruitmentSupabase
                        .from('recruitment_process')
                        .update({
                            interview_date: booking.booking_date,
                            interview_time_slot: booking.time_slot,
                            updated_at: new Date().toISOString()
                        })
                        .eq('application_id', booking.application_id),
                    recruitmentSupabase
                        .from('applications')
                        .update({
                            interview_date: booking.booking_date,
                            interview_time_slot: booking.time_slot,
                            updated_at: new Date().toISOString()
                        })
                        .eq('id', booking.application_id)
                ]);

                if (rpResult.error) {
                    console.error(`更新recruitment_process失败 (app_id: ${booking.application_id}):`, rpResult.error);
                }
                if (appResult.error) {
                    console.error(`更新applications失败 (id: ${booking.application_id}):`, appResult.error);
                }

                return { success: !rpResult.error && !appResult.error };
            } catch (err) {
                console.error(`同步失败 (app_id: ${booking.application_id}):`, err);
                return { success: false };
            }
        });

        const results = await Promise.all(updatePromises);
        const updateCount = results.filter(r => r.success).length;

        console.log(`面试日期同步完成: ${updateCount}/${uniqueBookings.length} 条记录`);
        return {
            success: true,
            message: `同步完成: ${updateCount}/${uniqueBookings.length} 条记录`,
            count: updateCount
        };
    } catch (error) {
        console.error('同步面试日期失败:', error);
        return { success: false, error: error.message };
    }
}

/**
 * 渲染表格
 */
function renderTable() {
    const pageData = dataManager.getPageData();
    table.render(pageData.data, CORE_FIELDS);
    updateTotalCount(pageData.pagination.totalCount);
}

/**
 * 更新总数显示
 */
function updateTotalCount(count) {
    document.getElementById('totalCount').textContent = `共 ${count} 条记录`;
}

/**
 * 更新分页
 */
function updatePagination() {
    const pagination = dataManager.getPageData().pagination;
    const container = document.getElementById('pagination');
    
    let html = '';
    
    // 上一页
    html += `<button ${pagination.currentPage === 1 ? 'disabled' : ''} onclick="goToPage(${pagination.currentPage - 1})">上一页</button>`;
    
    // 页码
    for (let i = 1; i <= pagination.totalPages; i++) {
        if (i === 1 || i === pagination.totalPages || (i >= pagination.currentPage - 2 && i <= pagination.currentPage + 2)) {
            html += `<button class="${i === pagination.currentPage ? 'active' : ''}" onclick="goToPage(${i})">${i}</button>`;
        } else if (i === pagination.currentPage - 3 || i === pagination.currentPage + 3) {
            html += `<span>...</span>`;
        }
    }
    
    // 下一页
    html += `<button ${pagination.currentPage === pagination.totalPages ? 'disabled' : ''} onclick="goToPage(${pagination.currentPage + 1})">下一页</button>`;
    
    container.innerHTML = html;
}

/**
 * 跳转到指定页
 */
function goToPage(page) {
    dataManager.getPageData(page);
    renderTable();
    updatePagination();
}

/**
 * 绑定事件
 */
function bindEvents() {
    // 搜索按钮
    document.getElementById('btnSearch').addEventListener('click', applyFilters);
    
    // 重置按钮
    document.getElementById('btnReset').addEventListener('click', resetFilters);
    
    // 导出按钮
    document.getElementById('btnExport').addEventListener('click', handleExport);
    
    // 打印按钮
    document.getElementById('btnPrint').addEventListener('click', handlePrint);
    
    // 强制同步按钮
    document.getElementById('btnForceSync').addEventListener('click', async () => {
        if (!confirm('确定要强制同步数据吗？这将从applications表重新同步所有数据。')) {
            return;
        }

        const result = await dataManager.syncFromApplications();

        if (result.success) {
            // 同步面试日期
            await syncInterviewDates();
            alert(result.message);
            await loadData();
        } else {
            alert('同步失败: ' + result.error);
        }
    });

    // 同步面试日期按钮
    const syncInterviewBtn = document.createElement('button');
    syncInterviewBtn.id = 'syncInterviewBtn';
    syncInterviewBtn.className = 'btn-secondary';
    syncInterviewBtn.innerHTML = '📅 同步面试日期';
    syncInterviewBtn.style.marginLeft = '10px';
    syncInterviewBtn.addEventListener('click', async () => {
        await syncInterviewDates();
        await loadData();
    });
    document.querySelector('.action-buttons')?.appendChild(syncInterviewBtn);
    
    // 数据质量检查按钮
    document.getElementById('btnDataQuality').addEventListener('click', handleDataQualityCheck);

    // 修复数据状态按钮
    document.getElementById('btnFixData')?.addEventListener('click', handleFixData);

    // 批量删除按钮
    document.getElementById('btnBatchDelete').addEventListener('click', handleBatchDelete);

    // 清除筛选按钮
    document.getElementById('btnClearFilter').addEventListener('click', clearStatFilter);

    // 筛选条件变化
    ['filterPosition', 'filterJobType', 'filterStage', 'filterStatus', 'filterTimeSlot'].forEach(id => {
        document.getElementById(id).addEventListener('change', applyFilters);
    });

    // 面试日期范围筛选
    document.getElementById('filterStartDate').addEventListener('change', handleDateRangeChange);
    document.getElementById('filterEndDate').addEventListener('change', handleDateRangeChange);

    // 清除日期范围筛选
    document.getElementById('btnClearDateRange').addEventListener('click', clearDateRangeFilter);

    // 搜索框回车
    document.getElementById('filterSearch').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') applyFilters();
    });
}

/**
 * 处理日期范围变化
 */
function handleDateRangeChange() {
    const startDate = document.getElementById('filterStartDate').value;
    const endDate = document.getElementById('filterEndDate').value;

    // 验证日期范围
    if (startDate && endDate) {
        if (new Date(startDate) > new Date(endDate)) {
            alert('起始日期不能晚于结束日期');
            document.getElementById('filterEndDate').value = '';
            return;
        }
    }

    // 更新UI状态
    updateDateRangeUI();

    // 应用筛选
    applyFilters();
}

/**
 * 更新日期范围筛选UI状态
 */
function updateDateRangeUI() {
    const startDate = document.getElementById('filterStartDate').value;
    const endDate = document.getElementById('filterEndDate').value;
    const dateRangeFilter = document.querySelector('.date-range-filter');
    const btnClearDate = document.getElementById('btnClearDateRange');

    if (startDate || endDate) {
        dateRangeFilter.classList.add('active');
        btnClearDate.style.display = 'inline-block';
    } else {
        dateRangeFilter.classList.remove('active');
        btnClearDate.style.display = 'none';
    }
}

/**
 * 清除日期范围筛选
 */
function clearDateRangeFilter() {
    document.getElementById('filterStartDate').value = '';
    document.getElementById('filterEndDate').value = '';
    updateDateRangeUI();
    applyFilters();
}

/**
 * 应用筛选
 */
function applyFilters() {
    const filters = {
        position: document.getElementById('filterPosition').value,
        job_type: document.getElementById('filterJobType').value,
        stage: document.getElementById('filterStage').value,
        status: document.getElementById('filterStatus').value,
        // 面试日期范围筛选
        interview_date_start: document.getElementById('filterStartDate').value,
        interview_date_end: document.getElementById('filterEndDate').value,
        interview_time_slot: document.getElementById('filterTimeSlot').value,
        search: document.getElementById('filterSearch').value.trim()
    };

    dataManager.applyFilters(filters);
    renderTable();
    updatePagination();
}

/**
 * 重置筛选
 */
function resetFilters() {
    document.getElementById('filterPosition').value = '';
    document.getElementById('filterJobType').value = '';
    document.getElementById('filterStage').value = '';
    document.getElementById('filterStatus').value = '';
    // 重置面试日期范围筛选
    document.getElementById('filterStartDate').value = '';
    document.getElementById('filterEndDate').value = '';
    updateDateRangeUI();
    document.getElementById('filterTimeSlot').value = '';
    document.getElementById('filterSearch').value = '';

    dataManager.resetFilters();
    renderTable();
    updatePagination();
}

/**
 * 显示详情
 */
async function showDetail(id) {
    const record = await dataManager.getRecord(id);
    if (record) {
        detailModal.show(record, DETAIL_FIELDS);
    }
}

/**
 * 处理流程操作
 */
async function handleProcess(id, stage) {
    const record = await dataManager.getRecord(id);
    if (!record) return;

    // 关键修复：根据按钮的 stage 参数（data-stage）决定打开哪个弹窗，而不是 current_stage
    if (stage === 'first') {
        // 初试处理
        firstInterviewModal.show(record, async (recordId, data) => {
            console.log('recruitment-process - 接收到的recordId:', recordId);
            console.log('recruitment-process - 接收到的data:', data);
            const result = await dataManager.processFirstInterview(recordId, data);
            if (result.success) {
                await loadData();
            } else {
                alert('处理失败: ' + result.error);
            }
            return result;
        });
    } else if (stage === 'second') {
        // 复试处理
        secondInterviewModal.show(record, async (recordId, data) => {
            const result = await dataManager.processSecondInterview(recordId, data);
            if (result.success) {
                await loadData();
            } else {
                alert('处理失败: ' + result.error);
            }
            return result;
        });
    } else if (stage === 'hired') {
        // 填写录用信息
        secondInterviewModal.show(record, async (recordId, data) => {
            const result = await dataManager.processHiring(recordId, data);
            if (result.success) {
                await loadData();
            } else {
                alert('处理失败: ' + result.error);
            }
            return result;
        });
    } else if (record.current_stage === 'hired') {
        // 录用阶段 - 根据是否接受offer决定显示哪个弹窗
        // 关键修复：支持多种accept_offer格式
        const hasAcceptedOffer = record.accept_offer === 'yes' || record.accept_offer === '是' || record.accept_offer === true || record.accept_offer === 1 || record.accept_offer === '1';
        const hasRejectedOffer = record.accept_offer === 'no' || record.accept_offer === '否';
        const hasNoReportReason = record.no_report_reason && record.no_report_reason.trim() !== '' && record.no_report_reason !== '无';
        // 关键修复：判断是否为已提交未报到状态（current_status为reject表示未报到）
        const isNotReported = record.current_status === 'reject' || record.current_status === 'rejected' || record.current_status === '不通过';

        // 关键修复：已拒绝状态不允许任何操作
        if (hasRejectedOffer) {
            alert('该候选人已拒绝offer，无法进行操作');
            return;
        }

        // 关键修复：未报到状态不允许任何操作
        if (hasNoReportReason || isNotReported) {
            alert('该候选人已标记为未报到，无法进行操作');
            return;
        }

        if (hasAcceptedOffer) {
            // 接受offer - 显示报到登记弹窗
            onboardingModal.show(record, async (recordId, data) => {
                const result = await dataManager.processOnboarding(recordId, data);
                if (result.success) {
                    await loadData();
                } else {
                    alert('处理失败: ' + result.error);
                }
                return result;
            });
        } else {
            // 未设置accept_offer - 显示复试弹窗填写录用信息
            secondInterviewModal.show(record, async (recordId, data) => {
                const result = await dataManager.processHiring(recordId, data);
                if (result.success) {
                    await loadData();
                } else {
                    alert('处理失败: ' + result.error);
                }
                return result;
            });
        }
    }
}

/**
 * 处理导出
 */
async function handleExport() {
    // 获取选中的记录ID
    const selectedIds = table.getSelectedIds();
    
    let data;
    if (selectedIds.length > 0) {
        // 只导出选中的记录
        const allData = dataManager.getPageData().data;
        data = allData.filter(row => selectedIds.includes(row.id));
    } else {
        // 如果没有选中记录，导出当前页所有数据
        data = dataManager.getPageData().data;
    }
    
    if (!data || data.length === 0) {
        alert('没有可导出的数据');
        return;
    }
    
    const fileName = `招聘流程数据_${new Date().toISOString().slice(0, 10)}`;
    exportManager.exportToExcel(data, fileName);
}

/**
 * 处理打印
 */
function handlePrint() {
    const data = dataManager.getPageData().data;
    exportManager.print(data);
}

/**
 * 处理强制同步
 */
async function handleForceSync() {
    if (!confirm('确定要强制同步数据吗？这将从应聘信息综合管理表中同步所有缺失字段。')) {
        return;
    }

    console.log('开始强制同步数据...');
    const result = await dataManager.syncFromApplications();

    if (result.success) {
        alert(result.message);
        await loadData();
    } else {
        alert('同步失败: ' + result.error);
    }
}

/**
 * 处理数据质量检查
 */
async function handleDataQualityCheck() {
    if (dataQualityChecker) {
        await dataQualityChecker.showReportModal();
    } else {
        alert('数据质量检查工具未初始化');
    }
}

/**
 * 处理修复数据状态
 * 根据 first_interview_result、second_interview_result 等字段重新计算 current_stage 和 current_status
 */
async function handleFixData() {
    if (!confirm('确定要修复数据状态吗？这将根据面试结果、录用状态等重新计算当前环节和状态。')) {
        return;
    }

    console.log('开始修复数据状态...');
    showLoading();
    
    try {
        const result = await dataManager.fixHistoricalData();
        
        if (result.success) {
            alert(result.message);
            console.log('修复完成:', result);
            // 修复完成后刷新数据
            await loadData();
        } else {
            alert('修复失败: ' + result.error);
        }
    } catch (error) {
        console.error('修复数据状态失败:', error);
        alert('修复失败: ' + error.message);
    } finally {
        hideLoading();
    }
}

/**
 * 手动添加记录
 */
async function addManualRecord(data) {
    const result = await dataManager.addRecord(data);
    if (result.success) {
        await loadData();
        return true;
    } else {
        alert('添加失败: ' + result.error);
        return false;
    }
}

/**
 * 编辑记录
 */
async function editRecord(id, data) {
    const result = await dataManager.updateRecord(id, data);
    if (result.success) {
        await loadData();
        return true;
    } else {
        alert('更新失败: ' + result.error);
        return false;
    }
}

/**
 * 删除记录
 */
async function deleteRecord(id) {
    if (!confirm('确定要删除这条记录吗？此操作不可恢复。')) {
        return false;
    }
    
    const result = await dataManager.deleteRecord(id);
    if (result.success) {
        await loadData();
        return true;
    } else {
        alert('删除失败: ' + result.error);
        return false;
    }
}

/**
 * 更新批量删除按钮显示状态
 */
function updateBatchDeleteButton(selectedIds) {
    const btnBatchDelete = document.getElementById('btnBatchDelete');
    if (selectedIds && selectedIds.length > 0) {
        btnBatchDelete.style.display = 'inline-block';
        btnBatchDelete.textContent = `🗑️ 批量删除 (${selectedIds.length})`;
    } else {
        btnBatchDelete.style.display = 'none';
    }
}

/**
 * 处理批量删除
 */
async function handleBatchDelete() {
    const selectedIds = table.getSelectedIds();
    
    if (!selectedIds || selectedIds.length === 0) {
        alert('请先选择要删除的记录');
        return;
    }
    
    if (!confirm(`确定要删除选中的 ${selectedIds.length} 条记录吗？\n\n此操作不可恢复，请谨慎操作！`)) {
        return;
    }
    
    showLoading();
    
    const result = await dataManager.batchDeleteRecords(selectedIds);
    
    if (result.success) {
        alert(`删除成功：${result.deletedCount} 条记录`);
        table.clearSelection();
        updateBatchDeleteButton([]);
        await loadData();
    } else {
        alert('删除失败: ' + result.error);
    }
    
    hideLoading();
}

/**
 * 批量操作
 */
async function batchProcess(action, ids) {
    if (!ids || ids.length === 0) {
        alert('请先选择记录');
        return;
    }
    
    if (!confirm(`确定要对选中的 ${ids.length} 条记录执行此操作吗？`)) {
        return;
    }
    
    // 批量操作实现
    const results = await Promise.all(
        ids.map(id => dataManager.updateRecord(id, { batch_action: action }))
    );
    
    const successCount = results.filter(r => r.success).length;
    alert(`操作完成：成功 ${successCount} 条，失败 ${ids.length - successCount} 条`);
    
    await loadData();
}

/**
 * 刷新数据
 */
async function refreshData() {
    await loadData();
}

/**
 * 获取当前筛选条件
 */
function getCurrentFilters() {
    return dataManager.getCurrentFilters();
}

/**
 * 设置每页显示数量
 */
function setPageSize(size) {
    dataManager.setPageSize(size);
    renderTable();
    updatePagination();
}

// ============================================
// 回收站功能
// ============================================

// 全局变量
let recycleBinData = [];
let selectedRecycleBinIds = new Set();

/**
 * 显示回收站模态框
 */
function showRecycleBin() {
    document.getElementById('recycleBinModal').classList.add('active');
    loadRecycleBinData();
}

/**
 * 关闭回收站模态框
 */
function closeRecycleBin() {
    document.getElementById('recycleBinModal').classList.remove('active');
}

/**
 * 加载回收站数据
 */
async function loadRecycleBinData() {
    const container = document.getElementById('recycleBinContainer');
    container.innerHTML = '<div class="loading-message">正在加载回收站数据...</div>';

    try {
        const result = await dataManager.loadDeletedData();
        
        if (result.success) {
            recycleBinData = result.data;
            document.getElementById('recycleBinCount').textContent = recycleBinData.length;
            renderRecycleBin(recycleBinData);
        } else {
            container.innerHTML = '<div class="empty-state"><p>加载失败: ' + result.error + '</p></div>';
        }
    } catch (error) {
        console.error('加载回收站数据失败:', error);
        container.innerHTML = '<div class="empty-state"><p>加载失败，请重试</p></div>';
    }
}

/**
 * 渲染回收站列表
 */
function renderRecycleBin(data) {
    const container = document.getElementById('recycleBinContainer');

    if (data.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>回收站为空</p></div>';
        document.getElementById('recycleBinBulkActions').style.display = 'none';
        return;
    }

    let html = '<table class="recycle-bin-table"><thead><tr>';
    html += '<th style="width: 40px;"><input type="checkbox" id="selectAllRecycleBin" onchange="toggleAllRecycleBin(this)"></th>';
    html += '<th>姓名</th>';
    html += '<th>电话</th>';
    html += '<th>岗位</th>';
    html += '<th>当前环节</th>';
    html += '<th>删除时间</th>';
    html += '<th>删除人</th>';
    html += '<th style="width: 200px;">操作</th>';
    html += '</tr></thead><tbody>';

    data.forEach((item, index) => {
        const deletedAt = item.deleted_at ? new Date(item.deleted_at).toLocaleString('zh-CN') : '-';
        const deletedBy = item.deleted_by || '系统';
        const stageMap = {
            'application': '投递简历',
            'first_interview': '初试',
            'second_interview': '复试',
            'hired': '录用',
            'onboarded': '已报到'
        };
        const stageLabel = stageMap[item.current_stage] || item.current_stage || '-';

        html += `<tr class="deleted-row">`;
        html += `<td><input type="checkbox" class="recyclebin-checkbox" value="${item.id}" onchange="updateRecycleBinSelections()"></td>`;
        html += `<td>${item.name || '-'}<span class="deleted-badge">已删除</span></td>`;
        html += `<td>${item.phone || '-'}</td>`;
        html += `<td>${item.position || '-'}</td>`;
        html += `<td>${stageLabel}</td>`;
        html += `<td class="delete-info">${deletedAt}</td>`;
        html += `<td class="delete-info">${deletedBy}</td>`;
        html += `<td>`;
        html += `<button class="btn-restore" onclick="restoreFromRecycleBin('${item.id}')" style="margin-right: 8px; padding: 4px 12px; font-size: 12px;">♻️ 恢复</button>`;
        html += `<button class="btn-permanent-delete" onclick="permanentDeleteFromRecycleBin('${item.id}', '${item.name || ''}')" style="padding: 4px 12px; font-size: 12px;">⚠️ 彻底删除</button>`;
        html += `</td></tr>`;
    });

    html += '</tbody></table>';
    container.innerHTML = html;
}

/**
 * 回收站：全选/取消全选
 */
function toggleAllRecycleBin(checkbox) {
    const checkboxes = document.querySelectorAll('.recyclebin-checkbox');
    checkboxes.forEach(cb => cb.checked = checkbox.checked);
    updateRecycleBinSelections();
}

/**
 * 回收站：更新选中状态
 */
function updateRecycleBinSelections() {
    const checkboxes = document.querySelectorAll('.recyclebin-checkbox:checked');
    selectedRecycleBinIds.clear();
    checkboxes.forEach(cb => selectedRecycleBinIds.add(cb.value));
    
    const count = selectedRecycleBinIds.size;
    document.getElementById('recycleBinSelectedCount').textContent = `已选择 ${count} 条记录`;
    document.getElementById('recycleBinBulkActions').style.display = count > 0 ? 'block' : 'none';
    
    // 更新全选状态
    const selectAll = document.getElementById('selectAllRecycleBin');
    const allCheckboxes = document.querySelectorAll('.recyclebin-checkbox');
    if (selectAll && allCheckboxes.length > 0) {
        selectAll.checked = count === allCheckboxes.length;
    }
}

/**
 * 回收站：清空选择
 */
function clearRecycleBinSelections() {
    selectedRecycleBinIds.clear();
    const checkboxes = document.querySelectorAll('.recyclebin-checkbox');
    checkboxes.forEach(cb => cb.checked = false);
    document.getElementById('recycleBinBulkActions').style.display = 'none';
}

/**
 * 从回收站恢复单条记录
 */
async function restoreFromRecycleBin(id) {
    if (!confirm('确定要恢复这条记录吗？')) return;

    try {
        const result = await dataManager.restoreRecord(id);
        
        if (result.success) {
            alert('恢复成功！');
            loadRecycleBinData();
            await loadData(); // 刷新主列表
        } else {
            alert('恢复失败: ' + result.error);
        }
    } catch (error) {
        console.error('恢复记录失败:', error);
        alert('恢复失败: ' + error.message);
    }
}

/**
 * 批量恢复
 */
async function batchRestoreFromRecycleBin() {
    const count = selectedRecycleBinIds.size;
    if (count === 0) {
        alert('请先选择要恢复的记录');
        return;
    }

    if (!confirm(`确定要批量恢复选中的 ${count} 条记录吗？`)) return;

    try {
        const ids = Array.from(selectedRecycleBinIds);
        const result = await dataManager.batchRestoreRecords(ids);
        
        if (result.success) {
            alert(result.message);
            clearRecycleBinSelections();
            loadRecycleBinData();
            await loadData(); // 刷新主列表
        } else {
            alert('批量恢复失败: ' + result.error);
        }
    } catch (error) {
        console.error('批量恢复失败:', error);
        alert('批量恢复失败: ' + error.message);
    }
}

/**
 * 彻底删除单条记录
 */
async function permanentDeleteFromRecycleBin(id, name) {
    if (!confirm(`⚠️ 警告：彻底删除后数据将无法恢复！\n\n确定要彻底删除 "${name || '该记录'}" 吗？`)) return;

    try {
        const result = await dataManager.permanentDeleteRecord(id);
        
        if (result.success) {
            alert('已彻底删除！');
            loadRecycleBinData();
        } else {
            alert('删除失败: ' + result.error);
        }
    } catch (error) {
        console.error('永久删除失败:', error);
        alert('删除失败: ' + error.message);
    }
}

/**
 * 批量彻底删除
 */
async function batchPermanentDeleteFromRecycleBin() {
    const count = selectedRecycleBinIds.size;
    if (count === 0) {
        alert('请先选择要删除的记录');
        return;
    }

    if (!confirm(`⚠️ 警告：此操作将永久删除选中的 ${count} 条记录，且无法恢复！\n\n确定要继续吗？`)) return;

    try {
        const ids = Array.from(selectedRecycleBinIds);
        const result = await dataManager.batchPermanentDeleteRecords(ids);
        
        if (result.success) {
            alert(result.message);
            clearRecycleBinSelections();
            loadRecycleBinData();
        } else {
            alert('批量删除失败: ' + result.error);
        }
    } catch (error) {
        console.error('批量永久删除失败:', error);
        alert('批量删除失败: ' + error.message);
    }
}

/**
 * 清空回收站
 */
async function emptyRecycleBin() {
    if (recycleBinData.length === 0) {
        alert('回收站已经是空的');
        return;
    }

    if (!confirm(`⚠️ 警告：此操作将永久删除回收站中的所有 ${recycleBinData.length} 条记录，且无法恢复！\n\n确定要继续吗？`)) return;

    try {
        const result = await dataManager.emptyRecycleBin();
        
        if (result.success) {
            alert(result.message);
            loadRecycleBinData();
        } else {
            alert('清空回收站失败: ' + result.error);
        }
    } catch (error) {
        console.error('清空回收站失败:', error);
        alert('清空回收站失败: ' + error.message);
    }
}

// 暴露全局函数供HTML调用
window.goToPage = goToPage;
window.showDetail = showDetail;
window.handleProcess = handleProcess;
window.handleExport = handleExport;
window.handlePrint = handlePrint;
window.resetFilters = resetFilters;
window.applyFilters = applyFilters;
window.refreshData = refreshData;
window.showRecycleBin = showRecycleBin;
window.closeRecycleBin = closeRecycleBin;
window.loadRecycleBinData = loadRecycleBinData;
window.toggleAllRecycleBin = toggleAllRecycleBin;
window.updateRecycleBinSelections = updateRecycleBinSelections;
window.clearRecycleBinSelections = clearRecycleBinSelections;
window.restoreFromRecycleBin = restoreFromRecycleBin;
window.batchRestoreFromRecycleBin = batchRestoreFromRecycleBin;
window.permanentDeleteFromRecycleBin = permanentDeleteFromRecycleBin;
window.batchPermanentDeleteFromRecycleBin = batchPermanentDeleteFromRecycleBin;
window.emptyRecycleBin = emptyRecycleBin;