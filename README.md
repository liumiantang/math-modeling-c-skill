# 数学建模 C 题建模协作 Skill

面向数学建模竞赛 C 类题目的可复用 Codex skill，涵盖：

- 题意机制识别与数据审计
- 预测—决策建模
- 网络流与调度建模
- 情景规划与鲁棒优化
- MATLAB MCP 实际验证
- 误差、敏感性、稳定性和可行性分析
- 论文复盘与结论边界控制

## 安装到 Codex

将本仓库中的 `SKILL.md` 放入你的 Codex skills 目录：

```text
<CODEX_HOME>/skills/math-modeling-c-problem-solving/SKILL.md
```

安装后，在建模任务中调用或提及该 skill 即可使用。

## 注意

这个仓库只包含建模工作流和方法规范，不包含个人数据、MATLAB 许可证或 MATLAB MCP 连接。要实际运行 MATLAB，使用者需要自行配置 MATLAB 和对应 MCP。

本 skill 不把相关性包装成因果关系，也不把时间限制下的可行解包装成全局最优。
## 本次升级

仓库现在同时包含：

- 可自动发现的数学建模 C 题 Skill；
- 题意机制卡、创新点筛选、盲题复盘、验证交付协议和论文一致性审计；
- matlab_c_workflow：预测—决策、网络/调度、不确定性优化三类 MATLAB 工作流；
- 结果护照生成器 generateModelPassport.m；
- 论文数字一致性审计器 auditPaperConsistency.m；
- tests/test_c_workflow_core.m：6 项 MATLAB 单元测试。

### MATLAB 冒烟测试

在 MATLAB 中将仓库目录设为当前目录后运行：

    addpath('matlab_c_workflow');
    results = runtests('matlab_c_workflow/tests/test_c_workflow_core.m');

测试通过后，再将自己的数据审计、模型运行、敏感性分析和结果护照接入正式论文流程。数字审计采用结果清单驱动，不能替代人工检查公式、图表语义和竞赛格式。
