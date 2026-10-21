# TimescaleDB 2.20.0 + PostgreSQL 17 Alpine 3.11 (ABI 1.0)

本目录为龙芯 **ABI 1.0（旧世界）** 的 TimescaleDB 叠层镜像。

## 与 ABI 2.0 Alpine 方案的区别

| 项目 | ABI 2.0 (Alpine 3.22) | ABI 1.0 (Alpine 3.11) |
|---|---|---|
| 基础镜像 | `lcr.loongnix.cn/library/postgres:17-alpine3.22` | `cr.loongnix.cn/library/postgres:17-alpine3.11` |
| 编译工具 | `clang19` / `llvm19` | `gcc` / `build-base` |
| pgvector | 包含 | **不包含**（Alpine 3.11 源缺失） |
| timescaledb-tune | 包含 | **不包含**（golang 镜像不可用） |

## 构建

```bash
make image
