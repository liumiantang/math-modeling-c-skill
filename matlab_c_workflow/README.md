# MATLAB C 题自动化工作流

本目录把三类 C 题固化为同一条可复用流程：

```text
数据审计 → 机制识别 → 候选模型竞争 → MATLAB 求解 → 结果校验
        → 误差/稳定性/敏感性分析 → 可复现报告
```

## 三类入口

- `predictionDecisionWorkflow.m`：预测—决策题。支持时间顺序切分、滚动回测、候选预测器比较、误差评价和决策函数。
- `networkSchedulingWorkflow.m`：网络/调度题。支持逐时段最小费用流、供需/容量约束和调度可行性检查。
- `robustOptimizationWorkflow.m`：不确定性优化题。支持名义情景、扰动情景、最坏目标、约束违反和敏感性网格。

## 共同工具

- `auditData.m`：缺失值、负值、维度、重复键和基本统计审计。
- `validateSolution.m`：统一检查目标值、等式残差、不等式违反、边界和自定义检查器。
- `rollingBacktest.m`：滚动时间窗误差评价。
- `sensitivityGrid.m`：自动遍历参数网格并记录输出。
- `run_matlab_c_workflow_demo.m`：用可控小数据完整运行三类工作流，作为安装后的冒烟测试。

## 使用原则

1. 先填数据结构和题意假设，再调用入口函数；不要把默认参数当成题面事实。
2. 每个模型必须提供假设、变量、目标函数和约束的说明字段。
3. 所有外推模型都必须按时间顺序切分，不能随机打乱时间序列。
4. 求解成功不等于结果正确，必须检查残差、容量、边界、目标重算和敏感性。
5. 任何“全局最优”表述都必须对应明确的完整可行域和求解器证据；否则写成“在给定离散/情景空间内的最优或可行解”。



## 统一入口

run_matlab_c_workflow.m 接收 prediction、network 或 robust，并把其余参数转发到对应工作流。例如：

result = run_matlab_c_workflow('prediction', data, cfg);
result = run_matlab_c_workflow('network', cost, supply, demand, cfg);
result = run_matlab_c_workflow('robust', scenarios, solveFcn, evaluateFcn, cfg);

## 自动化复核工具

新增工具把计算结果和论文交付连接起来：

- generateModelPassport.m：生成 Markdown/JSON 结果护照；若提供 key_numbers 表，还会生成 _result_manifest.csv。
- auditPaperConsistency.m：按结果清单和容差检查论文纯文本中的关键数字，生成 paper_consistency_audit.csv。
- tests/test_c_workflow_core.m：覆盖审计、回测、可行性、敏感性、护照和论文数字核验的单元测试。

示例调用流程：

1. 构造包含 key_numbers 表的 meta 结构体；
2. 调用 p = generateModelPassport(meta, 'model_passport.md')；
3. 调用 audit = auditPaperConsistency('paper.txt', p.manifestPath, 'paper_audit.csv')；
4. 查看 audit.pass 和 audit.audit 表；
5. 使用 runtests('tests/test_c_workflow_core.m') 运行测试。

论文数字审计要求输入 Markdown 或已提取的纯文本；它不会假装可靠地解析复杂 DOCX/PDF 排版。

## 文件格式协议

本工作流默认输出 Markdown、LaTeX、PDF 矢量图、CSV 和原始 MATLAB .m 文件。Markdown 是论文源稿，PDF 是最终编译稿；不生成 Word 源稿。MATLAB 图形优先使用 exportgraphics 的 vector 模式，表格和结果数字只写入 CSV，附录直接引用实际运行的 .m 文件。
