// 数据库连接测试脚本
// 直接在浏览器控制台运行

console.log('=== 开始数据库连接测试 ===');

// Supabase 配置
const SUPABASE_URL = 'https://dxrghlqnwfwpuxjvyisv.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4cmdobHFud2Z3cHV4anZ5aXN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2ODYyMjAsImV4cCI6MjA5MDI2MjIyMH0.r6hDrTVZ1p_Qq6sHuLeBEo3SFqGEh0trwbRMXLWnrNQ';

// 检查 Supabase SDK 是否加载
if (!window.supabase) {
  console.error('❌ Supabase SDK 未加载');
  console.error('请确保已引入 Supabase SDK 脚本');
} else {
  console.log('✅ Supabase SDK 已加载');
  
  // 初始化数据库客户端
  const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
  console.log('✅ 数据库客户端初始化成功');
  
  // 测试数据库连接
  async function testConnection() {
    console.log('\n=== 测试数据库连接 ===');
    
    try {
      // 测试 templates 表
      console.log('测试 templates 表...');
      const { data: templatesData, error: templatesError } = await db.from('templates').select('id').limit(1);
      if (templatesError) {
        console.error('❌ templates 表访问失败:', templatesError);
      } else {
        console.log('✅ templates 表访问成功，数据:', templatesData);
      }
      
      // 测试 field_configs 表
      console.log('\n测试 field_configs 表...');
      const { data: fieldConfigsData, error: fieldConfigsError } = await db.from('field_configs').select('id').limit(1);
      if (fieldConfigsError) {
        console.error('❌ field_configs 表访问失败:', fieldConfigsError);
      } else {
        console.log('✅ field_configs 表访问成功，数据:', fieldConfigsData);
      }
      
      // 测试 template_field_mappings 表
      console.log('\n测试 template_field_mappings 表...');
      const { data: mappingsData, error: mappingsError } = await db.from('template_field_mappings').select('id').limit(1);
      if (mappingsError) {
        console.error('❌ template_field_mappings 表访问失败:', mappingsError);
      } else {
        console.log('✅ template_field_mappings 表访问成功，数据:', mappingsData);
      }
      
      // 测试 field_options 表
      console.log('\n测试 field_options 表...');
      const { data: optionsData, error: optionsError } = await db.from('field_options').select('id').limit(1);
      if (optionsError) {
        console.error('❌ field_options 表访问失败:', optionsError);
      } else {
        console.log('✅ field_options 表访问成功，数据:', optionsData);
      }
      
      // 测试数据插入
      console.log('\n=== 测试数据操作 ===');
      console.log('测试数据插入...');
      const testTemplate = {
        name: '测试模板',
        description: '用于测试数据库连接的模板'
      };
      
      const { data: insertData, error: insertError } = await db.from('templates').insert([testTemplate]).select();
      if (insertError) {
        console.error('❌ 数据插入失败:', insertError);
      } else {
        console.log('✅ 数据插入成功，ID:', insertData[0].id);
        
        // 测试数据查询
        console.log('测试数据查询...');
        const { data: queryData, error: queryError } = await db.from('templates').select('*').eq('name', '测试模板');
        if (queryError) {
          console.error('❌ 数据查询失败:', queryError);
        } else {
          console.log('✅ 数据查询成功，找到', queryData.length, '条记录:', queryData);
        }
        
        // 测试数据删除
        console.log('测试数据删除...');
        const { error: deleteError } = await db.from('templates').delete().eq('id', insertData[0].id);
        if (deleteError) {
          console.error('❌ 数据删除失败:', deleteError);
        } else {
          console.log('✅ 数据删除成功');
        }
      }
      
    } catch (error) {
      console.error('❌ 测试过程中出现异常:', error);
    }
  }
  
  // 运行测试
  testConnection();
}

console.log('=== 测试脚本执行完成 ===');
