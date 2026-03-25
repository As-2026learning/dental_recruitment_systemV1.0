/**
 * Supabase 配置文件
 * 
 * 使用说明：
 * 1. 将下面的 YOUR_SUPABASE_URL 替换为您在Supabase控制台获取的 Project URL
 * 2. 将 YOUR_SUPABASE_ANON_KEY 替换为您在Supabase控制台获取的 anon public key
 */

const SUPABASE_URL = 'https://ztybxgnelynmsgkeqosz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0eWJ4Z25lbHlubXNna2Vxb3N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNjc1NjAsImV4cCI6MjA4OTg0MzU2MH0.ISKHxvS_1hR5SkluCQ69O6UQNDHMOisPacaRlm0d33M';

// 时段配置
const TIME_SLOTS = {
  morning: {
    label: '上午场 (09:00-10:30)',
    capacity: 15
  },
  afternoon: {
    label: '下午场 (13:00-15:30)',
    capacity: 25
  }
};

// 可预约的工作日（周一至周五）
const WORKING_DAYS = [1, 2, 3, 4, 5]; // 0=周日, 1=周一, ..., 6=周六

// 预约提前时间限制（小时）
const BOOKING_ADVANCE_HOURS = 2;

// 可预约的未来天数
const MAX_BOOKING_DAYS = 30;

// 岗位列表（可根据实际需求修改）
const POSITIONS = [
  '义齿设计师',
  'CAD/CAM技术员',
  '模型制作员',
  '烤瓷技术员',
  '质检员',
  '生产主管',
  '其他'
];
