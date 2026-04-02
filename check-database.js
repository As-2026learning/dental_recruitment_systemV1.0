const { createClient } = require('@supabase/supabase-js');

// 配置 Supabase
const supabaseUrl = 'https://dxrghlqnwfwpuxjvyisv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4cmdobHFud2Z3cHV4anZ5aXN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2ODYyMjAsImV4cCI6MjA5MDI2MjIyMH0.r6hDrTVZ1p_Qq6sHuLeBEo3SFqGEh0trwbRMXLWnrNQ';
const supabase = createClient(supabaseUrl, supabaseKey);

function log(message, type = 'info') {
    const timestamp = new Date().toLocaleTimeString();
    const prefix = type === 'error' ? '❌' : type === 'success' ? '✅' : type === 'warning' ? '⚠️' : 'ℹ️';
    console.log(`[${timestamp}] ${prefix} ${message}`);
}

async function checkDatabaseStructure() {
    log('开始检查数据库结构...');

    try {
        // 1. 检查 applications 表
        log('检查 applications 表...');
        const { data: appsData, error: appsError } = await supabase
            .from('applications')
            .select('*')
            .limit(5);

        if (appsError) {
            log(`读取 applications 表失败: ${appsError.message}`, 'error');
        } else {
            log(`读取到 ${appsData.length} 条应聘信息`, 'success');
            appsData.forEach(app => {
                log(`  - ID: ${app.id}, 姓名: ${app.name}, 岗位: ${app.position}`, 'info');
            });
        }

        // 2. 检查 bookings 表
        log('检查 bookings 表...');
        const { data: bookingsData, error: bookingsError } = await supabase
            .from('bookings')
            .select('*')
            .limit(5);

        if (bookingsError) {
            log(`读取 bookings 表失败: ${bookingsError.message}`, 'error');
        } else {
            log(`读取到 ${bookingsData.length} 条预约信息`, 'success');
            bookingsData.forEach(booking => {
                log(`  - ID: ${booking.id}, 姓名: ${booking.name}, 日期: ${booking.booking_date}, 时段: ${booking.time_slot}`, 'info');
            });
        }

        // 3. 检查特定记录
        log('检查特定记录 LISRG\t14789432677\t学徒\t3/30 周一\t上午场 09:00-10:00');
        
        // 查找预约记录
        const { data: targetBooking, error: bookingError } = await supabase
            .from('bookings')
            .select('*')
            .eq('phone', '14789432677')
            .eq('position', '学徒');

        if (bookingError) {
            log(`查找预约记录失败: ${bookingError.message}`, 'error');
        } else if (targetBooking.length > 0) {
            log(`找到预约记录:`, 'success');
            targetBooking.forEach(booking => {
                log(`  - 预约ID: ${booking.id}, 姓名: ${booking.name}, 日期: ${booking.booking_date}, 时段: ${booking.time_slot}, application_id: ${booking.application_id}`, 'info');
            });
            
            // 尝试通过 application_id 查找应聘记录
            if (targetBooking[0].application_id) {
                const { data: targetApplication, error: appError } = await supabase
                    .from('applications')
                    .select('*')
                    .eq('id', targetBooking[0].application_id);

                if (appError) {
                    log(`通过 application_id 查找应聘记录失败: ${appError.message}`, 'error');
                } else if (targetApplication.length > 0) {
                    log(`找到关联的应聘记录:`, 'success');
                    targetApplication.forEach(app => {
                        log(`  - 应聘ID: ${app.id}, 姓名: ${app.name}, 岗位: ${app.position}`, 'info');
                    });
                } else {
                    log(`未找到关联的应聘记录，application_id: ${targetBooking[0].application_id}`, 'warning');
                }
            } else {
                log(`预约记录没有关联的 application_id`, 'warning');
                
                // 尝试通过手机号查找应聘记录
                const { data: phoneApps, error: phoneAppError } = await supabase
                    .from('applications')
                    .select('*')
                    .eq('phone', '14789432677');

                if (phoneAppError) {
                    log(`通过手机号查找应聘记录失败: ${phoneAppError.message}`, 'error');
                } else if (phoneApps.length > 0) {
                    log(`通过手机号找到应聘记录:`, 'success');
                    phoneApps.forEach(app => {
                        log(`  - 应聘ID: ${app.id}, 姓名: ${app.name}, 岗位: ${app.position}`, 'info');
                    });
                } else {
                    log(`未找到通过手机号关联的应聘记录`, 'warning');
                }
            }
        } else {
            log(`未找到预约记录`, 'warning');
        }

        log('数据库结构检查完成！', 'success');
    } catch (error) {
        log(`检查过程中发生错误: ${error.message}`, 'error');
    }
}

// 运行检查
checkDatabaseStructure();
