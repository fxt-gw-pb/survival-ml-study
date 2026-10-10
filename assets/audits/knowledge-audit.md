# 项目自学网站：知识材料与修正实现审计

核对日期：2026-10-10。本文只整理项目已有材料、现有脚本和已有验证表；未重新训练模型，未生成新的性能结果。

项目相对路径约定：

- `ML/` 指 `蒸馏后的/machine_learning/`。
- `SRC/` 指 `小庞统计——生存机器学习预测3.0版本/小庞统计——生存机器学习预测3.0版本/`。
- 本报告路径：`自学网站/research/knowledge-audit.md`。

## 1. 阅读范围与来源层次

本次完整阅读 `ML/` 内 36 个 `SKILL.md`（27 个 `pang-survml*`、9 个历史 `survival-*`）、41 个 `references/*.md`、1 个 `README.md`、`SKILLS_INDEX.md`、全部 20 个 `_validation/*.csv` 和 1 个 `session_info.txt`。大表按 CSV 完整解析所有记录，并检查行数、字段、数值和关联关系；没有仅根据头几行推断整表。

为核实“修正版本能做什么”，另完整阅读了 27 个 `pang-survml*/scripts/*.R`，以及保存的原始使用说明。原始主脚本、原始 PDF 的具体画面及 RData 函数体由网站主任务的其他材料审查补充；本报告不把未见到的图内数值当作新发现。

网站应始终保留五个来源层次：

| 层次 | 入口 | 适合用于网站的内容 | 不能据此声称 |
|---|---|---|---|
| 原始主脚本 | `SRC/1.生存机器学习模型3.0版本.R` | 1283 行分析流程、代码细节、原始超参数 | 所有保存的图都来自这个版本的一次运行 |
| 原始结果和工作空间 | `SRC/*_Result/`、两个 `.RData`、六个 CSV | 77 张原图、已有预测、历史对象 | 这些结果互相完全一致，或已完成无泄漏外部验证 |
| 历史蒸馏版 | `ML/survival-machine-learning/`、`ML/survival-ml-*/` | 原始代码分段、方法说明、预检查 | 它是新版完整实现的权威入口 |
| 新模块规范及脚本 | `ML/pang-survml*/` | 27 个模块、修正原则、可独立调用的现有 R 脚本 | 文档列出的全部调参、概率预测、置信区间和交付物已自动实现或已跑通 |
| 合成样图 | `ML/example/` | 8 种输出形态的教学演示 | 图中 AUC、校准、DCA、KM、SHAP 数值是真实项目结果 |

权威模块入口依据 `ML/SKILLS_INDEX.md` 是 `pang-survml`；旧 `survival-ml-*` 保留作历史资料。网站可以并列展示“原始实现”“修正理由”“现有脚本”“验证状态”，让学习者看见代码如何演进。

## 2. 可直接展示的项目事实

### 2.1 原始材料规模

`ML/_validation/source_inventory/source_file_manifest.csv` 和 `ML/_validation/artifact_audit/artifact_manifest.csv` 均包含 121 条历史文件记录，路径、MD5 一致。这 121 项全部存在且 MD5 一致。网页版收录原始目录的 128 个文件，另有 7 个 DOCX 包装材料补充到历史清单。

历史清单收录的资料共 155,936,268 字节，网页版收录原始文件共 156,960,025 字节；文件类别如下：

| 类别 | 数量 | 说明 |
|---|---:|---|
| PDF | 77 | 既有审计文档记录均可读、均为 1 页 |
| R 源文件 | 7 | 主脚本、CoxBoost 安装脚本、CoxBoost 5 个 R 实现文件 |
| CSV | 6 | 原始数据、标签训练/测试数据、Cox 表、数值预测表 |
| RData | 2 | 原始模型工作空间与 SHAP 工作空间 |
| CoxBoost Rd 文档 | 15 | 包接口和实现说明 |
| C 源文件 | 2 | CoxBoost 编译实现 |
| TXT | 2 | 使用说明和包安装说明 |
| 其他 | 10 | ZIP、tar.gz、README、Rproj、包元数据、历史文件等 |

77 张 PDF 分布：AUC/C-index 4、校准 18、DCA 6、KM 16、ROC 7、SHAP 23、LASSO 2、列线图 1。既有逐页 PNG 与七张联系表在 `ML/_source_audit/pdf_renders/001.png` 至 `077.png`、`contact_01.png` 至 `contact_07.png`。

### 2.2 原始数据与验证目录数据

`SRC/data.csv` 有 2038 行、18 列，前两列为 `Time`、`Event`，其后 16 个数字编码预测变量；1224 个事件、814 个删失；无缺失单元格；65 条 `Time=0`；有 13 条整行重复。没有患者 ID，整行重复不能直接认定为同一患者的重复记录，也无法证明患者之间独立。

原始使用说明明确以月为时间单位。原始随访时间范围 0–119 月，中位数 21 月。以下仅为对已有 CSV 的描述性核对，不是生存概率或模型性能：

| 数据 | 行数 | 事件 | 删失 | Time 范围 | Time 中位数 | `Time=0.003` |
|---|---:|---:|---:|---|---:|---:|
| 原始 `SRC/data.csv` | 2038 | 1224 | 814 | 0–119 | 21 | 0 |
| `ML/_validation/split/development.csv` | 1427 | 857 | 570 | 0.003–119 | 21 | 49 |
| `ML/_validation/split/validation.csv` | 611 | 367 | 244 | 0.003–119 | 20 | 16 |

重新划分目录的 2038 条 `split_manifest.csv` 记录可以严格对应回原始数据，唯一数值变动是把原来的 65 个零时间改成 `0.003`。`exclusions.csv` 只有表头，没有排除记录。由数值可以确认采用了 epsilon 替换，但文件中没有保存用户理由、敏感性分析或不可变配置；不能说零时间问题已经得到充分的方法学解决。

新开发集与验证集之间有 8 种完全相同的整行记录，每个队列各 8 条。没有患者 ID，既不能证明它们是同一患者造成的泄漏，也不能保证这是独立队列；网站应把它作为需要原始身份信息核对的具体问题。

| 时点（月） | 原始数据中 `Time≥t` 的记录数 | 重新划分开发集 | 重新划分验证集 |
|---:|---:|---:|---:|
| 12 | 1402 | 977 | 425 |
| 24 | 920 | 650 | 270 |
| 36 | 666 | 476 | 190 |
| 60 | 329 | 236 | 93 |
| 70 | 236 | 168 | 68 |

以上是观测到的在险支持数量，适合作为“为何不能只改 time 参数”教学例子；不能据此认定每个时点已满足某个临床研究样本量标准。

原始 `Train_plot_data.csv` 与 `Test_plot_data.csv` 也是 1427/611 行，但 `_validation` 的新划分不是原来的成员顺序。`_validation/coxph/validation_coxph_predictions.csv` 与 `SRC/Test_plot_data.csv` 的 `Time/Event` 序列不相同，禁止跨这两版表按行拼接。

### 2.3 16 个候选变量、8 个主要变量

完整原始列顺序：

`Time, Event, Age, Race, Gender, Grade, Surgery, Radiotherapy, Chemotherapy, Marital, AJCC_stage, T_stage, N_stage, M_stage, SEER_stage, Fibrosis_score, Tumor_size, Income`。

| 变量 | 原始 CSV 的实际数字值 | 网站教学重点 |
|---|---|---|
| Age | 0、1 | 已分组的数字编码，并非原始连续年龄 |
| Race | 1、2、3 | 类别编码不能自动解释为线性梯度 |
| Gender | 0、1 | 必须查字典才知道参考组 |
| Grade | 1、2、3、4 | 源标签有 `GreadI`–`GreadIV` 拼写问题 |
| Surgery | 0、1 | 不能从预测关联推断治疗因果作用 |
| Radiotherapy | 0、1 | 源标签中的 `No/Unknown` 混合含义需保留 |
| Chemotherapy | 0、1 | 同上；单、多因素方向变化可作为调整示例 |
| Marital | 0、1 | 编码类别与临床定义需从字典核实 |
| AJCC_stage | 1、2、3、4 | 与其他分期变量可能有关联 |
| T_stage | 1、2、3、4 | 数字编码与 factor 处理不是同一模型 |
| N_stage | 0、1 | 参考类别应明确 |
| M_stage | 0、1 | 原始 Cox 表存在 `NA (NA-NA)` 条目 |
| SEER_stage | 1、2、3 | 数字线性效应与分类效应要区分 |
| Fibrosis_score | 0、1 | 已编码变量，不应凭名称猜连续原值 |
| Tumor_size | 0、1 | 原数据已分组，不能声称是连续肿瘤尺寸 |
| Income | 1、2、3 | 类别定义及缺失含义需要数据字典 |

当前主脚本手工指定的八变量：`Age, Race, Grade, Surgery, Chemotherapy, Marital, SEER_stage, Tumor_size`。这些是此项目示例的模型输入，不能作为新数据的通用最终变量。

来源：`ML/pang-survml-data/references/source-data-map.md`、`ML/pang-survml/references/data-contract.md`、`ML/survival-machine-learning/references/data-contract.md`、原始 `data.csv` 和主脚本编码块。

## 3. 自学顺序与课程内容

下列顺序可以直接组织成网站课程。每节均应有“概念—代码入口—现有结果—核对练习”，不要只有一张结果图。

| 节 | 学习目标与知识点 | 应看的项目材料 | 可设置的练习 |
|---|---|---|---|
| 1. 项目地图 | 一份项目为何有源代码、预测 CSV、模型对象、图形、验证报告；数据开发与模型评价的区别 | `ML/SKILLS_INDEX.md`、`ML/pang-survml/references/source-coverage.md`、121 文件清单 | 给一张图找到模型、队列、时点、版本和来源代码 |
| 2. 右删失数据 | `Time` 是事件或删失发生前的持续时间；`Event=0` 不代表永不发生事件；月与年；时间起点和预测窗口 | 使用说明、数据契约、preflight 报告 | 解释“36 月之前删失”的样本为什么不能简单当作 36 月存活对照 |
| 3. 数据审计与编码 | 16 个候选变量、二元/多类数字编码、factor 标签、参考组、无 ID、重复、缺失与零时间 | `pang-survml-data`、原始 factor 块、`prepare_split.R` | 找出 Age/Tumor_size 已二分；列出零时间处理的需要记录的依据 |
| 4. 划分与泄漏 | seed 123、70/30、按 Event 分层；开发/内部/外部验证；开发拟合预处理、调参和阈值 | `pang-survml/SKILL.md`、`methodological-corrections.md`、split CSV | 比较两版验证表，说明不能按行合并；指出哪些操作不能在验证集重做 |
| 5. Cox 回归 | 单因素与多因素、系数/HR/CI/p、条件调整、比例风险诊断、类别与连续效应 | `pang-survml-cox-screen`、`_validation/cox_screen/` | 解释 Chemotherapy 单、多因素方向变化；阅读 GLOBAL PH 检验 |
| 6. 列线图 | Cox 模型的可视化评分；基线生存与指定时点生存；风险分数不是概率 | `pang-survml-nomogram`、`Nomogram.pdf` | 审查 `failtime=c(1,3,5)` 与“月”单位之间的关系 |
| 7. LASSO | Cox 惩罚、系数路径、交叉验证偏差、`lambda.min` 与 `lambda.1se`、非零变量、model.matrix | `pang-survml-lasso`、两张 LASSO PDF | 分辨手工 `sigvar` 与 LASSO `rid`；解释为何 CV 内也要重做选择 |
| 8. 模型家族 | CoxPH/Lasso-Cox；森林；GBM/XGBoost/CoxBoost；SVM 排序；SuperPC/PLS 降维 | 9 个模型模块、训练原始分段 | 对照每个模型的输入形状、预测尺度、主要参数和保存对象 |
| 9. 预测契约 | `Time/Event`+模型列、稳定 ID、预测方向、列名、有限值、概率与排序分数 | `pang-survml-predictions`、两张原预测 CSV、原测试预测报告 | 哪些列可以直接用于 DCA？为何 `risk_range_ok=TRUE` 不代表这些分数在 [0,1]？ |
| 10. 区分度 | 时间依赖 AUC、时点 ROC、IPCW、全局 Harrell C-index、时间依赖 C-index、支持时点、不确定性 | `pang-survml-time-auc`、`pang-survml-cindex`、`pang-survml-roc` | 区分“排序好”和“概率准”；找到普通 pROC 对删失的处理问题 |
| 11. 校准与效用 | 固定时点绝对风险、KM 观测率、校准线、重校准与验证的差别、Brier、DCA、阈值/treat-all/treat-none | `pang-survml-calibration`、`pang-survml-dca`、24 张相应 PDF | 解释“在测试集拟合一个 Cox 映射”为什么改变了验证对象 |
| 12. KM 风险分组 | 训练中位数、固定阈值、log-rank、置信带、risk table、分组图与连续分数评价 | `pang-survml-km`、16 张 KM PDF | 开发阈值应用于验证后，为什么两组不一定各占 50%？ |
| 13. SHAP | wrapper、解释目标、背景分布、Monte Carlo `nsim`、正负贡献、bar/beeswarm/force/waterfall/dependence | `pang-survml-shap`、23 张 SHAP PDF、SHAP RData | 同一变量的 SHAP 值处于哪个尺度？为何不是因果效应或固定时点生存概率？ |
| 14. 个体预测与复现 | PLS-R Cox app、代码字典、基线生存、模型版本；RData/RDS、包环境、MD5、报告清单 | `pang-survml-individual-predictor`、environment/artifact-audit/report | 找出当前 `plsrcox_model.rds` 尚未提供 app 所需的哪个字段 |

贯穿所有课程的总流程：预审查 → 明确划分/重抽样 → 在开发数据拟合预处理 → 在开发重抽样内选择变量/调参 → 锁定预测 → 评价 → 解释 → 报告。只保留一次随机划分不能等同于外部验证。

教学解释可以补足术语含义，但必须标明“对项目代码的解释”，不能给项目添加新的研究结论、虚构优胜模型、额外临床效应或未经运行的新指标。

## 4. 模型、参数与预测尺度

### 4.1 九种模型标签

原始使用说明说 8 个模型，当前主脚本训练 8 个：`RSF, GBM, Coxph, CoxBoost, Survivalsvm, xgboost, superpc, plsRcox`。历史图形/工作空间另出现 `Lasso_Cox`，所以材料库共需解释 9 种标签。

| 模型 | 代码/包 | 原始设置与输入 | 原始分数含义 | 新脚本实际行为 |
|---|---|---|---|---|
| RSF | 260–272；`randomForestSRC` | seed 123；1000 树、nodesize=3、mtry=2、logrank、importance/proximity | ensemble mortality/risk，不能当概率 | 仍 1000/3，mtry 为 `floor(sqrt(p))`；保存 importance、森林及两队列预测；没有自动网格调参 |
| GBM | 274–283；`gbm` | 1000 树、depth=5、node=3、shrinkage=.01、10-fold、6 cores | link score | 最大 3000 树、同深度/节点/学习率、10-fold、1 core；用 `gbm.perf(method='cv')` 的选定树数；其他参数仍固定 |
| CoxPH | 288–291；`survival` | 用选择的 8 变量拟合 `coxph` | 原始 CSV `type='risk'`，相对风险 | 输出 `type='lp'`；保存 PH 表和模型；没有自动导出指定时点概率 |
| Lasso-Cox | 当前模型块缺失；`glmnet` 或历史 post-LASSO Cox | 第一工作空间的 `Lasso_Cox` 类是 `coxph` | 历史 Cox 分数；真实拟合过程应追查 | 新模块训练的是 CV glmnet Cox，取 `lambda.min` 的 link；不能自动称为与历史 coxph 对象完全相同的模型 |
| CoxBoost | 295–305；`CoxBoost` | penalty 起点 200；maxstep=200；3-fold Verweij CV | linear predictor | 改成 10-fold；开发集罚项/步数优化；预测用占位 newtime/status 而非验证结局；保存 pen/cv/model |
| Survival-SVM | 311–322；`survivalsvm` | linear kernel、gamma.mu=.5、quadprog、makediff3、margin=.1、bound=10 | ranking score | 基本保留固定参数；未实现文档要求的标准化、超参数搜索 |
| XGBoost Cox | 327–345；`xgboost` | `survival:cox`、`cox-nloglik`、eta=.03、depth=3、subsample/colsample=1、gamma=.5、100 rounds | Cox score；需核实版本的预测与标签语义 | 内部随机 80/20 holdout；最多 2000 轮、50 轮早停；未用最终验证集；保存 inner_index；未自动按 Event 分层或全部开发集重训 |
| SuperPC | 348–365；`superpc` | feature×sample 转置；s0.perc=.5；20 thresholds；10 folds；最多 3 components；min 5 features；第一行最大 score 选 threshold | component score | 保留结构与 threshold；最终 `n.components=1`；没有自动从 1–3 成分选模型 |
| PLS-R Cox | 368–373；`plsRcox` | 10-component、10-fold CV，最终硬编码 nt=3 | package `type='risk'` 的分数 | 尝试 `cv$nt.opt`，没有此字段时回退 3；未验证 CV 对象接口，未生成 `baseline_survival` |

每个新模型脚本的接口基本为：`<development.csv> <validation.csv> <output_dir> [predictors_csv] [seed]`；CoxPH 不需 seed。适合网站展示相对路径命令模板，不应把这些命令写成已在本项目运行成功的全模型流水线。

### 4.2 风险方向与尺度

`ML/_validation/original_test_prediction_report.csv` 验证的是原始 611 行测试预测；8 列均无缺失、无非有限值，均非常量。以下为已有原始表的真实范围：

| 模型 | 最小 | 最大 | 唯一分数数 |
|---|---:|---:|---:|
| Coxph | 0.114803 | 7.769654 | 310 |
| CoxBoost | -1.609083 | 2.602204 | 310 |
| RSF | 12.172779 | 156.980702 | 310 |
| GBM | -2.106158 | 3.380987 | 310 |
| Survivalsvm | 21.585075 | 50.898055 | 310 |
| xgboost | 0.191679 | 6.495127 | 234 |
| superpc | -0.670347 | 1.207506 | 67 |
| plsRcox | 0.201609 | 13.968278 | 310 |

`risk_range_ok=TRUE` 是检查器的命名规则导致的：只有名称形如 `<model>__risk__<horizon>` 时检查 [0,1]。原始八列不符合此命名模式，因此 TRUE 不意味着概率已经校准。这是网站中很好的“字段名也属于数据契约”练习。

新 `_validation/coxph/` 的两表是 lp，范围均为 -2.261553–1.919791，开发集 447 个唯一值、验证集 291 个唯一值，Time/Event 与各自新版 split 完整对齐。不能直接把新 lp 与旧相对风险同轴比较数值大小，不能把任何原始模型分数称作 36 月风险概率。

来源：所有模型各自 `references/source-parameters.md`、`ML/survival-machine-learning/references/models-and-outputs.md` 和完整新脚本。

## 5. 已有 Cox 验证结果：可展示但须解释编码

`ML/_validation/cox_screen/` 是对八个数字编码变量的重新拟合。每个变量只出现一个系数；Race、Grade、SEER_stage 等在这些 CSV 输入中没有被还原为 factor，所以该系数是数字编码的单位变化效应。不能把它标成类别间相对于某参考组的 HR，也不能与原始 41 行分类 Cox 表直接视为同一个模型。

| 变量 | 单因素 HR | 多因素 HR | 多因素 95% CI | 多因素 p |
|---|---:|---:|---|---:|
| Age | 1.4429 | 1.1939 | 1.0349–1.3772 | 0.0151 |
| Race | 0.9321 | 0.9284 | 0.8534–1.0101 | 0.0841 |
| Grade | 1.2106 | 1.2307 | 1.1208–1.3514 | 1.37e-5 |
| Surgery | 0.2458 | 0.2627 | 0.2241–0.3078 | 3.33e-61 |
| Chemotherapy | 1.2595 | 0.6639 | 0.5725–0.7699 | 5.99e-8 |
| Marital | 1.2493 | 1.1758 | 1.0266–1.3467 | 0.0193 |
| SEER_stage | 2.2335 | 1.5929 | 1.4259–1.7794 | 1.74e-16 |
| Tumor_size | 2.6019 | 1.8237 | 1.5754–2.1112 | 8.55e-16 |

PH 检验在 `_validation/cox_screen/ph_test.csv` 与 `_validation/coxph/ph_test.csv` 完全相同：GLOBAL χ²=104.7449、df=8、p=4.5624e-19。Grade、Surgery、Chemotherapy、SEER_stage、Tumor_size 的 PH p 值分别约 1.66e-5、0.00208、7.36e-9、1.27e-6、0.00906。Age/Race/Marital 的该诊断 p 值较大。

网站要明确这是比例风险假设的诊断证据。显著 HR 或较好的排序表现不能替代模型假设检查；这些表不是治疗因果结论，也不能据此描述一个通过所有诊断的临床模型。

原始 Cox 表的已知问题：`autoReg(..., uni=TRUE, milti=TRUE, threshold=.05)`，手工选八变量，41 行保存结果中 M-stage 多因素条目 `NA (NA-NA)`，需保留为不稳定/共线性的核对点。来源为 `ML/pang-survml-cox-screen/references/source-result.md` 与 `SRC/训练集单因素多因素Cox回归.csv`。

## 6. 图形与评价知识

### 6.1 时间依赖 AUC、ROC、C-index

- AUC：原始脚本为每个模型分数拟合一个 Cox 适配器，使用 `riskRegression::Score`，时点 `seq(0,70,5)`，AUC 图有 0.7 参考线。参考线是绘图设置，不能把它作为临床可用性的通用判断标准。原始图没有可见的不确定性带。
- C-index：原始脚本使用 `pec::cindex`；对象被覆盖和部分验证集重拟合导致适配器来源不一致。新脚本在开发集拟合适配器，验证集计算全局 Harrell concordance 和时间依赖 cindex。
- ROC：原始 horizon 重编码后调用 pROC，把 t 前删失者当作对照；这种图不能当作正确处理删失的时点 ROC。新模块采用 `timeROC`/IPCW。
- 图形版本：现有 ROC 包括训练 12/24/36/60、测试 12/36/60，当前代码循环是 12/36/60。24 月文件应列为历史额外产物。
- 现有新脚本使用 `iid=TRUE`，但 AUC/ROC 没导出置信区间；文档“报告不确定性”是要求，不是这些输出已经具备的事实。
- `time_roc.R` 单个时点调用后固定取 `o$AUC[1]` 和 `FP/TP[,1]`，没有按返回 `o$times` 匹配目标时点；某些接口可能含额外时点，应标“返回结构待验证”，不要未经运行声称其曲线正确。
- `time_auc.R` 直接将请求 `tt` 与 `o$AUC` 拼成 data.frame，同样应在支持单时点和多时点前核对返回长度/顺序。当前保存环境缺少 timeROC，这些脚本尚无本项目成功运行的记录。

网站可以讲清楚：AUC/ROC/C-index 衡量排序或区分，不能说明概率校准，也不能单独证明净获益。不同模型应在同一个样本、结局定义、时点及验证设计下比较。

具体来源：`ML/pang-survml-time-auc/references/source-map.md`、`ML/pang-survml-roc/references/source-map.md`、`ML/pang-survml-cindex/references/source-map.md`、相应脚本、4 张 AUC/C-index 和 7 张 ROC PDF。

### 6.2 校准和 DCA

- 原始校准在每个队列内重新对分数拟合 `rms::cph`，在 12/36/60 月 bootstrap。开发集拟合模型在验证集的固定预测评价，和在验证集重新拟合一个新模型，是不同的问题。
- 现有文件有 9 张训练校准和 9 张测试校准（含 Lasso_Cox 与 Coxph），当前八模型代码会生成 8+8；不要删除这两张历史差异来制造一致性。
- 原始 DCA 将每个分数经过队列内 Cox 生存映射再用于 12/36/60 月；有些曲线标签是 Lasso-Cox，有些是 CoxPH。
- 新校准/DCA 契约要求列名 `<model>__risk__<horizon>`，且概率在 [0,1]，来自开发模型和开发基线风险。当前新训练脚本通常只输出分数，没有自动生成这些风险列，因此不是可以无缝串联的全自动流水线。
- `calibration_groups.R` 按预测风险分位数分组，每组用 KM 的 `1-S(t)` 作为观察发生率，输出表和 PDF。它未实现校准截距、斜率、Brier、置信带或 bootstrap；也没在脚本内验证概率范围。`summary(..., extend=TRUE)` 可能在稀疏随访组延续最后生存值，支持时点仍需检查。
- `run_dca.R` 输出净获益 CSV/PDF，使用 `dcurves::dca`。脚本没有暴露临床阈值区间参数，文档的阈值合理性必须人工配置/解释。

建议图旁设置核对问题：输入是排序分数还是时点概率？基线/映射在哪个队列拟合？同一模型是否在验证时被改了？图内是否存在置信区间？

来源：`ML/pang-survml-calibration/*`、`ML/pang-survml-dca/*`、`ML/survival-ml-calibration-dca/references/code-map.md`。

### 6.3 KM 风险组

- 原始代码对每个模型在训练集用本队列中位数分高低风险，测试集再次计算测试中位数，决策规则发生变化。
- 新 `km_by_locked_cutoff.R` 从开发分数求中位数，保存 `development_cutoffs.csv`，并在验证集原样应用，`score>cutoff` 为 high，其余为 low。
- 图应读出置信带、risk table、组数、log-rank p、时间范围；中位数分组只是描述性展示，主要评价仍要保留连续分数的区分度和概率校准。
- 新脚本目前输出固定阈值和 PDF，但没有单独导出组数表和 log-rank 数值表；文档要求这些交付物，脚本尚未全部具备。
- 既有参考文档记录测试 Survival-SVM 分组 p≈0.053，其余多数分离强。网站若展示此数，应该直接链接并核对 `SRC/KM_Result/Test_Survivalsvm_survival.pdf`，不能把“分离强”改写成一个新的综合模型排序。

来源：`ML/pang-survml-km/*`、`ML/survival-ml-km/*`。

### 6.4 SHAP

本项目涉及五种图形：bar（全局平均绝对贡献）、beeswarm（每个样本贡献的分布并关联特征值）、force（个体贡献合成）、waterfall（个体逐项贡献）、dependence（特征与贡献的关系）。这些解释的都是拟合模型在某个预测尺度上的输出，不能把正负 SHAP 自动解释成因果效应。

原始包装器目标：RSF mortality、GBM link、CoxPH risk、CoxBoost lp、Survival-SVM score、SuperPC score、plsRcox risk；XGBoost 使用原生 shapviz 路径。模拟数量为 100，seed 和背景数据都应记录。

现有 23 张 SHAP PDF 是 7 个历史模型各 3 张（bar、beeswarm、force，共 21 张）加 Survival-SVM waterfall 与 dependence 两张。七模型为 CoxBoost、GBM、LASSO_COX、RSF、Superpc、Survivalsvm、Xgboost。CoxPH/plsRcox 在当前代码里计算 SHAP，但未保存对应的图。reference 记录 dependence 是 16 面板；保存的 SHAP workspace 矩阵只有 8 变量，进一步说明历史图与当前 workspace 不可简单归为同一次运行。

新 `explain_score.R`：

- 支持 RSF、GBM、CoxPH、Lasso-Cox、CoxBoost、SVM、XGBoost、PLS-R Cox 的 switch；没有 SuperPC wrapper，提示自定义或原生路径。
- 写出 beeswarm、bar、第一行 waterfall 和 RDS；不写 force、dependence，也不默认在图标题写解释尺度。
- 固定 seed 123，默认 nsim=100，背景与被解释数据同一份 CSV。
- 自动从 CSV 去掉 ID/Time/Event 后取其余所有列，没有按保存的 `predictors` 筛选/排序。训练 8 变量时不能未经检查传入完整 16 变量表，尤其矩阵接口会出错或错序。
- payload 的识别方式是“若 list 且 `$model` 非空就取 `$model`”。`train_coxph.R` 保存的原生 `coxph` 本身是 list，且 `model=TRUE` 令 `$model` 为模型数据框，因此直接用该 CoxPH RDS 调 SHAP 会误把数据框当模型。这是静态代码能确认的接口缺口，不是已经修复的功能。
- 未自动调用前检查输出长度、有限性、列序或预测不变性；未提供固定时点绝对风险 wrapper。默认第一行个体图应明确其选择规则。

来源：`ML/pang-survml-shap/*`、`ML/survival-ml-shap/references/code-map.md`、RData 对象清单和 SHAP 原图。

## 7. RData、个体预测和版本一致性

两个工作空间在 CSV 清单中共 181 对象，分别 62 与 119；包括隐藏 `.Random.seed`。默认 `ls()` 不包含隐藏对象时会看到 61 与 118，这两个统计并不矛盾。

| 文件 | 有代表性的保存对象 | 重要区别 |
|---|---|---|
| `SRC/Survival_ML_model.RData` | `Lasso_Cox`（coxph）、`RSF`（rfsrc）、`GBM`（gbm）、`fit/cvfit`、各单模型预测 | `x/x1` 为 1427×16，`coef.min` 16×1；保存的是较早的变量版本 |
| `SRC/Survival_ML_model_SHAP.RData` | `Coxph`、`nom1/res.cox/Nomo_train/Nomo_test`、`ui/server`、`base_surv/cox_surv/plsRcox_base`、`shap_RSF/shap_Survivalsvm` | `x/x1` 为 1427×8，两个 SHAP 矩阵均 1427×8，train/test 模型数据 1427×10/611×10；与第一版不是同一输入规模 |

对象名 `RSF`/`GBM` 在主脚本后续被用作 Cox 适配器名称，会失去算法对象；保存清单里它们仍可能是算法类，说明保存发生的阶段需要明确。建议教学中使用 `rsf_fit`、`rsf_score_adapter` 等不同名，保存显式 RDS，而非 `save.image()` 的整个全局环境。

第一 RData 的 RSF 对象内存大小约 271 MB，第二约 203 MB；压缩 RData 文件约 70/76 MB。工作空间载入依赖包命名空间，既有审计记录 plsRcox/randomForestSRC/xgboost/shiny 缺失警告，不应仅以 load 没报致命错误认定预测可复现。

个体预测 app 仅藏在 SHAP RData 的 `ui/server`，标题 “PLS-R Cox Survival Prediction”，八个输入使用旧数字编码，显示 1–5 年（12、24、36、48、60 月）生存与曲线，把基线生存升到某 risk 幂。这个概率转换和基线来源需要独立核查；主脚本没有生成 app 的代码。

新 `build_app.R` 可以生成 `app.R` 并复制 `model.rds`，标题增加 “Research Use Only”，动态生成 numericInput，检查 baseline 字段存在。但：

- `train_plsrcox.R` 的载荷没有 `baseline_survival`，现有两个脚本不能直接完整串联。
- 输入默认均为 0，没有类别 dropdown、有效值范围、缺失/异常值和编码说明。
- 保存模型版本/数据来源及概率校准验证仍需补齐。

适合作为“如何审查一个个体预测原型”的学习节；不能把未验证转换做成网站上的真实患者预测器并宣称临床可用。

## 8. 新模块能力核对：文档要求与实际代码

| 模块 | 代码中已经有的能力 | 文档要求但代码尚未完整实现的内容 | 保存验证目录的证据 |
|---|---|---|---|
| `pang-survml` preflight | 结构、缺失数、重复整行、零时间、事件值、计数、session；critical 时 exit 2 | 数字类型/有限性、ID/窗口/单位/结局的完整审查；不可变配置 | 已有报告：65 零时间为 critical |
| environment | 34 包 requireNamespace 和版本；缺包 exit 2 | 安装、兼容性复现、阶段依赖筛选 | 已有 package_audit |
| source-audit | 递归路径、类别、大小、MD5、模块路由、隔离读取 RData 对象 | PDF 渲染/页数/目视检查和问题表 | 已有两份源清单、23 段代码映射 |
| data | 0/1、Time/Event 无缺失、零时间 3 策略、按 Event 分层、split/exclusion CSV | 编码字典、ID/患者分组、开发拟合预处理；exclusion 后原始行号持续跟踪 | 已有两队列和 manifest；使用了 0.003 |
| cox-screen | 单/多因素、HR/CI/p、cox.zph、RDS | factor 映射、非线性、稀疏级别/共线性自动诊断 | 已有 8 变量表与 PH 表 |
| nomogram | 指定 horizon、开发拟合 rms cph、图、两队列 lp、RDS | 自动 PH 检验/风险 CSV/校准；完整配置 | 无对应运行产物 |
| lasso | model.matrix、glmnet/CV、两种 lambda 系数、PDF、terms/RDS | 保存 contrasts/xlevels/foldid 和重复嵌套重抽样 | 无对应运行产物 |
| rsf | 固定森林、importance、分数/RDS | mtry/nodesize/trees 调参、概率表、OOB 数据表 | 无对应运行产物 |
| gbm | CV 选树数、锁定预测树数、RDS | 深度/学习率/节点的调参、概率表 | 无对应运行产物 |
| coxph | 开发拟合、两队列 lp、PH、RDS | 指定时点概率、非线性/影响诊断自动化 | 已有两表和模型 |
| lasso-cox | CV lambda.min、矩阵列名相等检查、lp/RDS | 完整 levels/contrasts 契约、两种 lambda 预测、基线风险 | 无对应运行产物 |
| coxboost | 开发 penalty/steps CV、lp/RDS | 事件少时折数策略、完整预处理 | 无对应运行产物 |
| survivalsvm | 固定线性 SVM、分数/RDS | 标准化和多参数调优、风险方向与绝对风险 | 无对应运行产物 |
| xgboost | 内部 holdout、早停、符号时间、inner index/RDS | 分层 holdout、最佳轮数/预测行为的版本验证、全开发重新拟合 | 无对应运行产物 |
| superpc | feature×sample、CV threshold、训练结构/RDS | 在多个 component 中选择最佳；完整 SHAP adapter | 无对应运行产物 |
| plsrcox | CV 尝试组件选择、risk/RDS | CV 返回字段确认、无硬编码 fallback、baseline survival | 无对应运行产物 |
| predictions | 分数缺失/finite/常量和命名概率范围 | ID join、Time/Event 正确性、数值类型、重复模型列检查 | 已有原测试表审计 |
| shap | 多 wrapper、bar/beeswarm/row1 waterfall、RDS | SuperPC、force/dependence、risk wrapper、标题尺度、输入列约束、原生 coxph 载荷识别 | 无新 SHAP 运行产物 |
| time-auc | timeROC IPCW、AUC 表、PDF+300 dpi PNG | CI、在险支持检查、返回索引验证 | 无对应运行产物 |
| cindex | 开发适配器、验证全局 C/se/正态 CI、pec 时间 C | 两队列完整表、时间 C 的不确定性 | 无对应运行产物 |
| roc | timeROC、曲线/AUC CSV/PDF | 时点索引验证、CI、统一 300 dpi PNG | 无对应运行产物 |
| calibration | 分组预测均值、KM 观察率、PDF/CSV | 截距/斜率/Brier/CI/稀疏支持处理 | 无对应运行产物 |
| dca | horizon 概率列、dcurves、CSV/PDF | 业务阈值配置、输入范围检查 | 无对应运行产物 |
| km | 开发中位数锁定、同阈值两队列、图中 p/置信带/risk table | 单独 group-count/log-rank 数据表、方向契约、PNG | 无对应运行产物 |
| individual-predictor | 生成 Shiny 原型、研究标签、baseline 存在检查 | 基线生成/转换验证、字典和值域、版本/溯源 | 无新 app 运行产物 |
| artifact-audit | 全文件 hash、RData 类/维度/大小、CSV schema | PDF 阅读/页数、输出标签跨文件关联 | 已有两份对象/CSV 清单 |
| report | 文件角色/路径/MD5 清单 | 所有结果自动汇总、方法结果文字、配置与警告检查 | 已有 comprehensive manifest |

`ML/_validation/` 只提供 preflight、环境包审计、split、Cox screening、CoxPH 预测/模型、原预测审计、源/对象/文件清单。其他模型的新模块训练、SHAP、IPCW 评价、校准、DCA、KM、app 没有该目录中的成功运行产物，不能统一标为“已验证”。

## 9. 方法学与实现陷阱清单

网站至少保留以下 20 条核对点，每条都能关联已有项目材料：

1. **月与年混用**：原说明写月，列线图 `1,3,5` 不能直接称作 1/3/5 年。
2. **零时间**：原始 65 条，旧脚本和保存重划分都用了 0.003；没有理由不能默认为合适。
3. **编码转换分叉**：保存 train/test 是标签 factor，后面读原 numeric CSV；分类模型与数值模型不同。
4. **无患者 ID**：重复检测、队列独立性、跨表 join 都只能做到有限核对。
5. **行数一致不等于成员一致**：原始 611 行和重新划分 611 行 Time/Event 序列不同。
6. **八模型与九标签**：Lasso_Cox 与 Coxph 同时出现在产物，不能合并标签。
7. **历史 coxph 与新版 glmnet Lasso-Cox**：学习同一名字下对象类型变化。
8. **选择嵌套问题**：Cox/LASSO 筛选若在 CV 外完成，会影响泛化估计。
9. **调参文档不等于调参实现**：RSF/SVM/GBM 大部分参数仍固定。
10. **XGBoost 早停来源**：旧版本只监控训练矩阵；新版本应核对内部 holdout 和最佳轮数行为。
11. **PLS-R Cox CV 与最终组件**：旧硬编码 3，新 fallback 3，不能直接说组件问题已解决。
12. **模型对象覆盖**：后续 Cox 适配器覆盖算法名，SHAP/预测要保存原算法对象。
13. **验证集重拟合**：旧校准/DCA/部分 score adapter 在测试结局上再拟合。
14. **普通 pROC 和删失**：t 前删失并不等于 t 时无事件对照。
15. **KM 分割规则**：测试中位数改变规则；锁定开发阈值更符合固定预测评价。
16. **分数不等于概率**：负数/百量级 risk score 可排序，不能直接进入概率校准/DCA。
17. **PH 诊断确有问题**：验证目录 GLOBAL p≈4.56e-19；不能省略这项结果。
18. **SHAP 尺度与因果**：输出目标各异；颜色/正负是模型输出贡献，不是治疗效果。
19. **SHAP 模块契约不完整**：CoxPH 载荷误识别、SuperPC 缺 wrapper、列顺序不锁定。
20. **原型与部署**：app 缺基线契约和值域，不能把它变成没有来源说明的患者风险计算器。

原始项目、历史蒸馏版、新模块说明都要求保留源作者归属。网站材料库应保留原脚本头部归属，不应声称所有算法与方法由网站作者提出。

## 10. 环境和哈希解释

`ML/_validation/package_audit.csv` 是一个保存的环境快照：34 个包中只有 5 个已安装（survival 3.8.6、tidyr 1.3.2、ggplot2 4.0.3、dplyr 1.2.1、scales 1.4.0），其余 29 个记录为缺失。不要把它写成用户当前 Mac 的安装状态。

`session_info.txt` 记载 R 4.6.1（2026-06-24 ucrt）、Windows 11 x64、Chinese Simplified locale、Asia/Shanghai。网站可以展示它说明“运行环境也是结果材料的一部分”，不能声称这是本次浏览器自学网站的运行环境。

依赖按功能学习：survival/rms/autoReg/regplot 是 Cox 与列线图；glmnet 为惩罚选择；randomForestSRC/gbm/CoxBoost/survivalsvm/xgboost/superpc/plsRcox 对应算法；riskRegression/pec/timeROC 为生存评价；dcurves/ggDCA 为 DCA；survminer 为 KM；fastshap/shapviz 为解释；ggplot2/ggsci/gridExtra 等为绘图。旧脚本重复加载 survival/randomForestSRC/rms；无需每步加载全部包。

项目还捆绑 CoxBoost 源树及 ZIP（5 R、2 C、15 Rd）、`distr6_1.6.9.tar.gz`，以及历史安装路径。教学可读 DESCRIPTION、NAMESPACE、man、R、src 的分工，不能直接沿用作者桌面硬编码路径，也不能把历史版本说成当前最新依赖。

`ML/_validation/comprehensive_skill_manifest.csv` 有 282 条记录，分类为 93 figure、22 table/data、2 model/object、118 support、47 code。所有所列文件仍存在且哈希一致，只有它自身这一行的哈希不一致：清单包含自身，在写出自身时内容改变。这不是其他文件损坏的证据。自学网站的新清单宜排除自己的输出路径，或把清单校验值保存在另一个独立位置。

## 11. 网站表述规则与结果组织

建议每个页面都给出来源 badge：**原始结果**、**保存验证**、**合成演示**、**修正原则**、**现有代码待运行**。这些是来源说明，不是新的研究级别认证。

- “原始 AUC/ROC/KM 图片”可直接放图库，说明队列、时点、模型标签和原始路径，保留其方法学问题。
- “已保存验证”用于 preflight、Cox 表、PH 表、已有数值范围；数值引用到 CSV，按需要用表展示。
- “合成演示”用于 `ML/example/` 全部 8 图，必须就近标“演示数据”。
- “修正原则”说明为什么需训练阈值、IPCW、固定预测、概率契约、不同对象名。
- “现有代码待运行”列命令、输入与输出契约、实际实现和缺口，不标成功性能。
- 模型比较页面不要自行选“最佳模型”；原材料未提供一致的独立验证和完整不确定性证据。展示已有结果、核对任务和比较维度即可。
- 学习页中的自测问题可以给答案和代码出处；答案应围绕实际项目，不添加不存在的患者亚组结果。
- 所有 77 原始图应能按类别/模型/队列/时点搜索。图文件名里有特殊大小写、`LASSO_COX`/`Lasso_Cox`/`Coxph` 的别名，网站显示名可以统一，溯源路径必须保留原样。
- 不把图片“看起来很好”当作数字结论，不从采样绘图像素生成虚构 AUC 表。
- PDF 对应的 PNG 仅为预览，原 PDF 应保留可阅读入口；RData 应归为对象材料，不在网页加载执行。

最终自学路径应该让读者既能复述原作者流程，也能指出流程中的问题并知道修正版当前还有哪些缺口。

## 12. 完整文档与验证入口清单

### 12.1 新版 27 模块（每行均已读 SKILL 与脚本）

`ML/` 下的目录：

`pang-survml`、`pang-survml-environment`、`pang-survml-source-audit`、`pang-survml-data`、`pang-survml-cox-screen`、`pang-survml-nomogram`、`pang-survml-lasso`、`pang-survml-rsf`、`pang-survml-gbm`、`pang-survml-coxph`、`pang-survml-lasso-cox`、`pang-survml-coxboost`、`pang-survml-survivalsvm`、`pang-survml-xgboost`、`pang-survml-superpc`、`pang-survml-plsrcox`、`pang-survml-predictions`、`pang-survml-shap`、`pang-survml-time-auc`、`pang-survml-cindex`、`pang-survml-roc`、`pang-survml-calibration`、`pang-survml-dca`、`pang-survml-km`、`pang-survml-individual-predictor`、`pang-survml-artifact-audit`、`pang-survml-report`。

新版 references：总控下 `source-coverage.md`、`data-contract.md`、`methodological-corrections.md`；其余模块各一个 reference，共 29 个：environment `package-map.md`，source-audit `expected-inventory.md`，data `source-data-map.md`，cox-screen `source-result.md`，nomogram/lasso/predictions/time-auc/cindex/roc/calibration/dca/km 为 `source-map.md`，rsf/gbm/coxph/coxboost/survivalsvm/xgboost/superpc/plsrcox 为 `source-parameters.md`，lasso-cox `version-discrepancy.md`，shap `model-wrappers.md`，individual-predictor `rdata-app.md`，artifact-audit `known-findings.md`，report `delivery-checklist.md`。

### 12.2 历史 9 模块与 12 个 reference

- `ML/survival-machine-learning/SKILL.md`：references `data-contract.md`、`workflow.md`、`models-and-outputs.md`、`source-audit.md`。
- `ML/survival-ml-setup/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-data/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-select/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-train/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-shap/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-discrimination/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-calibration-dca/SKILL.md` 及 `references/code-map.md`。
- `ML/survival-ml-km/SKILL.md` 及 `references/code-map.md`。

### 12.3 验证 CSV/文本（全部已解析）

| 项目相对路径（前缀 `ML/_validation/`） | 记录数 | 用途 |
|---|---:|---|
| `preflight/preflight_report.csv` | 9 | 2038 行的结构审查 |
| `preflight/session_info.txt` | 文本 | 保存 Windows/R/locale 快照 |
| `package_audit.csv` | 34 | 包安装/版本快照 |
| `split/development.csv` | 1427 | 重新划分开发集 |
| `split/validation.csv` | 611 | 重新划分验证集 |
| `split/split_manifest.csv` | 2038 | 原始行号/所属队列 |
| `split/exclusions.csv` | 0 | 本次无排除记录 |
| `cox_screen/univariable_cox.csv` | 8 | 数字编码单因素结果 |
| `cox_screen/multivariable_cox.csv` | 8 | 数字编码多因素结果 |
| `cox_screen/ph_test.csv` | 9 | 8 变量+GLOBAL PH 检验 |
| `coxph/development_coxph_predictions.csv` | 1427 | 新模型 lp |
| `coxph/validation_coxph_predictions.csv` | 611 | 新模型锁定 lp |
| `coxph/ph_test.csv` | 9 | 同一个八变量 PH 诊断 |
| `original_test_prediction_report.csv` | 8 | 原始测试 8 分数列审查 |
| `source_inventory/main_script_line_map.csv` | 23 | 21 段主代码+2 个 workspace 独有内容 |
| `source_inventory/source_file_manifest.csv` | 121 | 路径/大小/MD5/模块 |
| `source_inventory/rdata_object_manifest.csv` | 181 | 对象名/类/尺寸/大小 |
| `artifact_audit/artifact_manifest.csv` | 121 | 同源 MD5 清单 |
| `artifact_audit/rdata_objects.csv` | 181 | 同源对象清单 |
| `artifact_audit/csv_schemas.csv` | 6 | 六个原始 CSV 字段 |
| `comprehensive_skill_manifest.csv` | 282 | 蒸馏目录所有支持材料、代码、图形及验证产物 |

合成样图入口：`ML/example/README.md`、`ML/example/figure_manifest.csv`（cohort split、LASSO paths、time AUC、ROC、calibration、DCA、KM、SHAP 8 项），`ML/example/00_example_gallery.png` 和 `figures/*.png`。
