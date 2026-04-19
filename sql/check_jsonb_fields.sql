: true,
  "hire_position": true,
  "first_interview_time": true,
  "first_interviewer": true,
  "first_reject_reason": true,
  "second_interview_time": true,
  "second_interviewer": true,
  "second_reject_reason": true
}
```

请确认哪些字段需要添加，我将立即创建 SQL 脚本。

## 总结

目前的问题：
1. **400 错误**：可能是由于 `first_interview` 等 `jsonb` 字段的处理方式不正确
2. **重复数据**：同步时未正确检测重复

请告诉我：
1. 是否需要添加缺失的字段？
2. 是否需要我修改代码，调整 `jsonb` 字段的处理方式？