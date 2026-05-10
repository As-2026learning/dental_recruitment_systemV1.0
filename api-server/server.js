/**
 * 义齿工厂招聘系统 - 后端 API 服务
 * 
 * 安全架构：前端 → 后端 API → Supabase Database
 * API Key 隐藏在服务端，不暴露给客户端
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 创建 Supabase 客户端（使用服务角色 Key，隐藏在服务端）
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// 请求日志
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// ============================================
// API 路由
// ============================================

/**
 * 获取应聘列表
 * GET /api/applications
 */
app.get('/api/applications', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('applications')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('获取应聘列表失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 获取单个应聘详情
 * GET /api/applications/:id
 */
app.get('/api/applications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('applications')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('获取应聘详情失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 创建应聘
 * POST /api/applications
 */
app.post('/api/applications', async (req, res) => {
  try {
    const applicationData = req.body;
    
    const { data, error } = await supabase
      .from('applications')
      .insert(applicationData)
      .select();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('创建应聘失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 更新应聘
 * PUT /api/applications/:id
 */
app.put('/api/applications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const { data, error } = await supabase
      .from('applications')
      .update(updateData)
      .eq('id', id)
      .select();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('更新应聘失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 获取招聘流程列表
 * GET /api/recruitment-process
 */
app.get('/api/recruitment-process', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('recruitment_process')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('获取招聘流程失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 获取单个招聘流程
 * GET /api/recruitment-process/:id
 */
app.get('/api/recruitment-process/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('recruitment_process')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('获取招聘流程详情失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 更新招聘流程
 * PUT /api/recruitment-process/:id
 */
app.put('/api/recruitment-process/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const { data, error } = await supabase
      .from('recruitment_process')
      .update(updateData)
      .eq('id', id)
      .select();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('更新招聘流程失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 创建招聘流程记录
 * POST /api/recruitment-process
 */
app.post('/api/recruitment-process', async (req, res) => {
  try {
    const processData = req.body;
    
    const { data, error } = await supabase
      .from('recruitment_process')
      .insert(processData)
      .select();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('创建招聘流程失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 获取预约列表
 * GET /api/bookings
 */
app.get('/api/bookings', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('bookings')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('获取预约列表失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 创建预约
 * POST /api/bookings
 */
app.post('/api/bookings', async (req, res) => {
  try {
    const bookingData = req.body;
    
    const { data, error } = await supabase
      .from('bookings')
      .insert(bookingData)
      .select();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (error) {
    console.error('创建预约失败:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({ 
    success: false, 
    error: '服务器内部错误' 
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log('='.repeat(50));
  console.log('义齿工厂招聘系统 - API 服务');
  console.log('='.repeat(50));
  console.log(`服务器运行在: http://localhost:${PORT}`);
  console.log(`API 文档:`);
  console.log(`  GET  /api/health              - 健康检查`);
  console.log(`  GET  /api/applications        - 获取应聘列表`);
  console.log(`  GET  /api/applications/:id    - 获取应聘详情`);
  console.log(`  POST /api/applications        - 创建应聘`);
  console.log(`  PUT  /api/applications/:id    - 更新应聘`);
  console.log(`  GET  /api/recruitment-process - 获取招聘流程`);
  console.log(`  PUT  /api/recruitment-process/:id - 更新招聘流程`);
  console.log(`  GET  /api/bookings            - 获取预约列表`);
  console.log(`  POST /api/bookings            - 创建预约`);
  console.log('='.repeat(50));
});

module.exports = app;
