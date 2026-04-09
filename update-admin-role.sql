-- 更新用户为管理员角色（如果已存在则更新，不存在则插入）
INSERT INTO public.user_roles (user_id, role, name)
VALUES ('93684d76-6a5b-4d4f-a61b-c0034e326fe3', 'admin', '系统管理员')
ON CONFLICT (user_id) 
DO UPDATE SET role = 'admin', name = '系统管理员';
