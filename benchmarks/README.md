# 回归基准（Regression Bench）

## 目标

为系统改动提供固定回归集，避免 skill 路由、记忆与守护脚本退化。

## 运行方式

```bash
bash scripts/benchmark/run_regression.sh
```

可指定案例文件和输出：

```bash
bash scripts/benchmark/run_regression.sh benchmarks/cases/smoke.list /tmp/regression.json
```

## 当前策略

1. PR/提交前至少运行 smoke 集。
2. 重点关注：`failed` 用例与 `pass_rate` 趋势。
3. 失败用例必须附修复说明再合并。
