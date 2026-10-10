# 原始结果材料审计

审计日期：2026-10-10。用途：为项目自学网站提供可追溯的结果数据、读图说明和复现边界。

## 范围与读数规则

本报告中的 `P/` 统一指项目相对目录：

`小庞统计——生存机器学习预测3.0版本/小庞统计——生存机器学习预测3.0版本/`

只读核对了这个目录中的全部 **77 个 PDF、6 个 CSV、7 个 DOCX**，并参考既有蒸馏材料。77 个 PDF 均为单页且能抽取文字。另对 ROC、C-index、校准、KM、SHAP force、SHAP dependence、列线图等样本进行 Poppler 渲染后的视觉检查。没有训练模型、修改原始文件或部署网站。

- **原图精确标注**：图中文字直接给出的数字，保留原图有效位数。这里的“精确”指准确抄录，并不意味着原分析无误。
- **当前 CSV 重算**：仅对现成预测列做成对秩比较，不重新拟合模型；和原 PDF 指标单独存放。
- **目测**：仅用于概括曲线形状和约略范围，不作为精确指标。
- **代码或文件关系推断**：明确指出证据和不确定性，不把不同运行的材料合并成同一套模型结果。

网站可读取的两个数据文件：

- `自学网站/research/roc-pdf-values.csv`：49 条原 PDF AUC/95% CI 标注，来自 7 张 ROC 图，每张 7 个模型名称。
- `自学网站/research/roc-current-csv-values.csv`：64 条现有预测 CSV 重算值，2 个数据集 × 4 个时间点 × 8 个模型。没有重算置信区间，`lower95/upper95` 留空。

两个表均有 `dataset,time,model,auc,lower95,upper95,source` 字段，另以 `definition,direction,precision` 说明口径。`source` 使用完整项目相对路径。

## 数据和文件关系

来源：`P/data.csv`、`P/traindata.csv`、`P/testdata.csv`、`P/Train_plot_data.csv`、`P/Test_plot_data.csv`。以下数量为直接数行和数值检查的精确结果。

| 项目 | 全部数据 | 原训练集 | 原测试集 |
| --- | ---: | ---: | ---: |
| 样本数 | 2038 | 1427 | 611 |
| Event=1 | 1224 | 851 | 373 |
| Event=0 | 814 | 576 | 238 |
| Time 最小值 / 最大值 | 0 / 119 | 0 / 119 | 0 / 119 |
| Time 中位数 | 21 | 21 | 20 |
| Time=0 | 65 | 50 | 15 |
| 全行唯一记录数 | 2025 | 1420 | 610 |

原始 `data.csv` 有 18 列：`Time, Event` 加 16 个特征：

`Age, Race, Gender, Grade, Surgery, Radiotherapy, Chemotherapy, Marital, AJCC_stage, T_stage, N_stage, M_stage, SEER_stage, Fibrosis_score, Tumor_size, Income`。

原始 16 个特征在 CSV 中全部使用数值类别编码。Age 是 `<65 / >=65` 二分类，Tumor_size 是 `<50mm / >=50mm` 二分类；不能按连续年龄或连续肿瘤大小解释。Income 也是三类别。`traindata.csv/testdata.csv` 保存了因子文字标签，如原拼写 `GreadI/GreadII/GreadIII/GreadIV`。按照主程序的因子映射把原始编码转换成标签后，训练集与测试集的全行多重集合之和**恰好等于 data.csv**。两个绘图 CSV 的 `Time/Event` 列与对应训练/测试 CSV 的逐行顺序完全一致。

输入三份数据 CSV 和两份绘图 CSV 未发现空字符串、NA、NaN 缺失值；绘图预测列亦没有非有限值。两份绘图 CSV 都是 10 列：`Time,Event` 加 `Coxph,CoxBoost,RSF,GBM,Survivalsvm,xgboost,superpc,plsRcox`，**没有 `Lasso_Cox` 列**。测试各列唯一预测数为：Coxph/CoxBoost/RSF/GBM/Survivalsvm/plsRcox 各 310，xgboost 234，superpc 67；预测重复本身不等于缺失，也不自动表明错误。

全数据有 13 条额外的完全重复行。训练和测试的全行多重集合交集有 5 条记录，表示存在相同的特征与结局组合；数据没有患者 ID，不能据此认定它们一定是同一患者。65 条 Time=0 中，63 条 Event=1，2 条 Event=0。主程序只在 LASSO 工作副本中将非正 Time 改成 0.003；原始数据和绘图 CSV 仍有 0。网站应保留这个事实，不能把所有原结果描述为已经通过正随访时长检查。

既有佐证：`蒸馏后的/machine_learning/_validation/preflight/preflight_report.csv` 同样记录 2038 行、18 列、13 个重复行、65 个非正 Time、1224 个事件、814 个删失；`蒸馏后的/machine_learning/_validation/artifact_audit/csv_schemas.csv` 记录这 6 份 CSV 的结构。

### 评估时间的支持程度

下表的“仍在风险集”严格定义为 CSV 中 `Time >= t`，不是模型估计，也不是完整生存分析的有效样本量。它可用于提醒学生观察长期曲线时样本支持逐渐减弱。

| t（主程序 DCA 注释明确为月） | 训练 Time>=t | 测试 Time>=t | 训练 t 前/当月已观测事件数 | 测试 t 前/当月已观测事件数 |
| --- | ---: | ---: | ---: | ---: |
| 12 | 983 | 419 | 450 | 189 |
| 36 | 475 | 191 | 722 | 327 |
| 60 | 225 | 104 | 826 | 359 |
| 70 | 167 | 69 | 844 | 364 |
| 90 | 75 | 32 | 848 | 371 |

例如，测试 60 月之前被删失的记录有 148 条；原 ROC 代码仍将这些人放入二元非事件对照组。来源：`P/testdata.csv`、`P/1.生存机器学习模型3.0版本.R` 的 ROC 段落。

## 原 ROC PDF 的完整 AUC/CI 表

以下均为**原图文字精确标注、保留三位小数**。表格中的 `Lasso_Cox` 名称按 PDF 保留，不能改称现有 CSV 的 `Coxph`。这些数值不应与当前保存预测列混用，也不应称为严格处理删失的时间依赖 AUC。主程序另一段 `riskRegression::Score(metrics="AUC")` 才是独立的生存 AUC 计算段落。

训练图来源：`P/ROC_Result/Train_ROC_12.pdf`、`Train_ROC_24.pdf`、`Train_ROC_36.pdf`、`Train_ROC_60.pdf`。

| 模型 | 12个月 AUC [95% CI] | 24个月 AUC [95% CI] | 36个月 AUC [95% CI] | 60个月 AUC [95% CI] |
| --- | --- | --- | --- | --- |
| GBM | 0.833 [0.809, 0.857] | 0.820 [0.797, 0.842] | 0.810 [0.788, 0.833] | 0.801 [0.778, 0.823] |
| RSF | 0.879 [0.861, 0.898] | 0.888 [0.871, 0.904] | 0.887 [0.871, 0.904] | 0.888 [0.871, 0.904] |
| Lasso_Cox | 0.831 [0.807, 0.854] | 0.811 [0.788, 0.834] | 0.800 [0.777, 0.823] | 0.790 [0.767, 0.814] |
| Survivalsvm | 0.574 [0.542, 0.606] | 0.593 [0.563, 0.623] | 0.587 [0.557, 0.616] | 0.576 [0.547, 0.606] |
| xgboost | 0.838 [0.815, 0.861] | 0.824 [0.802, 0.846] | 0.815 [0.793, 0.837] | 0.810 [0.787, 0.832] |
| superpc | 0.762 [0.735, 0.789] | 0.734 [0.708, 0.760] | 0.734 [0.708, 0.759] | 0.732 [0.706, 0.757] |
| plsRcox | 0.830 [0.806, 0.853] | 0.811 [0.788, 0.834] | 0.801 [0.778, 0.823] | 0.791 [0.768, 0.814] |

测试图来源：`P/ROC_Result/Test_ROC_12.pdf`、`Test_ROC_36.pdf`、`Test_ROC_60.pdf`。

| 模型 | 12个月 AUC [95% CI] | 36个月 AUC [95% CI] | 60个月 AUC [95% CI] |
| --- | --- | --- | --- |
| GBM | 0.828 [0.792, 0.865] | 0.796 [0.760, 0.831] | 0.777 [0.740, 0.814] |
| RSF | 0.828 [0.792, 0.863] | 0.792 [0.756, 0.828] | 0.772 [0.735, 0.810] |
| Lasso_Cox | 0.828 [0.791, 0.864] | 0.789 [0.754, 0.825] | 0.771 [0.734, 0.808] |
| Survivalsvm | 0.558 [0.509, 0.608] | 0.534 [0.489, 0.580] | 0.523 [0.476, 0.569] |
| xgboost | 0.823 [0.785, 0.861] | 0.791 [0.755, 0.827] | 0.774 [0.737, 0.811] |
| superpc | 0.766 [0.723, 0.808] | 0.736 [0.696, 0.775] | 0.719 [0.679, 0.759] |
| plsRcox | 0.826 [0.789, 0.862] | 0.789 [0.753, 0.825] | 0.771 [0.733, 0.808] |

可以教学生观察到：RSF 在训练图中的标注 AUC 较高，但测试图中多模型 AUC 接近，长时点较 12 月降低。不能仅根据三位小数的 AUC 排名断言某模型显著优于其他模型；表中的区间大量重叠，也没有配对模型差异检验结果。

### 现有预测 CSV 与历史 PDF 不一致

为了核验文件是否来自同次结果，仅对已保存的预测列做如下计算：

1. 与原脚本 ROC 段落一样，令 `Y=1` 当且仅当 `Event=1` 且 `Time<=t`；所有其他行当作二元对照。
2. AUC 为所有事件/对照预测值配对中“事件得分更大”比例，相同得分记 0.5。
3. 按 pROC 默认方向选择规则，以事件/对照预测中位数决定方向；事件中位数更低时使用反向 AUC。`direction='<'` 表示较大值趋向事件，`direction='>'` 表示较小值趋向事件。

这个重算**有意匹配原代码的普通二元 ROC 口径**来核验文件，不是修复删失处理的统计方法。没有重训、没有重拟合 Cox 模型，也没有估计置信区间。

以下当前 CSV 重算数值为显示到六位小数，原始导出表保留九位小数：

| 当前预测列 | 训练12 | 训练36 | 训练60 | 测试12 | 测试36 | 测试60 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Coxph | 0.826861 | 0.793718 | 0.785403 | 0.823416 | 0.787742 | 0.768272 |
| CoxBoost | 0.826852 | 0.793702 | 0.785401 | 0.823428 | 0.787774 | 0.768305 |
| RSF | 0.844225 | 0.841149 | 0.841413 | 0.818601 | 0.788463 | 0.771488 |
| GBM | 0.836016 | 0.811313 | 0.804415 | 0.819153 | 0.787397 | 0.774561 |
| Survivalsvm | 0.667725 | 0.660312 | 0.668985 | 0.687229 | 0.643257 | 0.632367 |
| xgboost | 0.831498 | 0.804515 | 0.798617 | 0.820563 | 0.789163 | 0.772168 |
| superpc | 0.724319 | 0.689905 | 0.668704 | 0.676634 | 0.660949 | 0.648362 |
| plsRcox | 0.826479 | 0.793512 | 0.785067 | 0.823942 | 0.787473 | 0.767818 |

例如，原图训练 12 月 RSF 标注 0.879，而当前预测 CSV 同口径为 0.844225；原图测试 12 月 SVM 标注 0.558，而现 CSV 同口径、自动方向为 0.687229。差异远大于三位小数的四舍五入误差。原图测试 12 月 GBM 标注 0.828，现 CSV 为 0.819153。加上 `Lasso_Cox` 名称缺失，这足以证明**不能把原 ROC 图当作当前这两份预测 CSV 的直接复核结果**。至于差异来自哪次代码/特征变化，单凭这几份材料不能确定。

### 图例、同值和重复核验

77 个 PDF 的 SHA-256 哈希均不同，解码后 PDF 页面内容流也均不同；不存在字节相同或页面内容流完全相同的 PDF 文件。相同轴标签文字不等于相同结果图。

`P/ROC_Result/Test_ROC_12.pdf` 的视觉核验发现：实际绘图区有 8 条 ROC 路径，文字图例仅 7 个模型名称；`Lasso_Cox` 的图例色样显示为橙粉色，和图中接近对角线的 SVM 色调一致，`Survivalsvm` 文字项旁无正常可见色样；另有灰色曲线没有清楚文字对应。网站应保留原图并提示“原图图例对应存在异常”，不能仅按颜色宣布哪条线是 Lasso。

测试 12 月 GBM、RSF 和 `Lasso_Cox` 都标注 AUC=0.828，但三者置信区间不同。直接检查 PDF 的长曲线路径：GBM 的青色 ROC 有 539 个路径节点，红橙路径有 527 个节点，橙粉路径有 555 个节点，坐标哈希均不同。**三位小数 AUC 相等不是相同预测排序或复制曲线的证据**。由于图例问题，不能把未经核实的某条色线强行对应到 Lasso 模型。

`Train_ROC_24.pdf` 是附加历史产物；当前主脚本 ROC 循环仅为 12、36、60 月，并无 24 月输出循环。测试没有 24 月 ROC PDF。不同历史文件的颜色方案也不完全相同，网站不能设定所有结果图都共用同一调色板。

## C-index 和随时间 AUC 图

来源：`P/AUC_Result/Train_C_index.pdf`、`Test_C_index.pdf`、`Train_AUC.pdf`、`Test_AUC.pdf`；代码来源：`P/1.生存机器学习模型3.0版本.R` 中 AUC 与 `pec::cindex` 段落。

这 4 个 PDF 仅有轴刻度和模型图例，**没有精确逐模型数字标签**。两份预测 CSV 保存的是风险分数，不是现成 C-index 表。不能从曲线目测编造精确到三位小数的 C-index 排名表，也不能把 ROC AUC 填进 C-index 卡片。

可安全提供的目测描述：C-index 图中较强几条曲线随评估时间降低，训练 RSF 在长时点约 0.77，测试较强曲线在长时点约 0.72-0.73；SVM 长时点曲线约 0.61-0.63。所有这些都是**目测近似**，不是从指标对象导出的精确值。原 C-index 图含 0、5、10…70 的评估点；原脚本 `eval.times=seq(0,70,5)`，且原数据含 Time=0，应在教学中解释它的输入边界。

主脚本 AUC 段先把原模型名称覆盖成 `coxph(Surv(Time,Event) ~ 单个已保存风险分数)`，再用 `riskRegression::Score`。测试 AUC 段还在测试集上重新拟合这种单风险分数 Cox 包装模型；训练 C-index 段中的部分对象在此时已经被测试包装覆盖。**这些曲线的计算对象不同于原生学习器直接输出的完整生存分布**。此外，`ylim(0.5,1)` 会使低于 0.5 的数据不在可见纵轴范围；图中无曲线不自动等于没有计算值。

## Cox 表、LASSO 和列线图

### Cox 回归表

来源：`P/训练集单因素多因素Cox回归.csv`，41 行，16 个变量的参考水平和对比水平。参考行的 HR 为空属于表格格式，不等于数据缺失。主要多因素标注如下，均为原表文字：

| 比较 | 多因素 HR [95% CI] | 原表 P |
| --- | --- | --- |
| Age >=65 vs <65 | 1.21 [1.04,1.40] | .011 |
| Race Other vs White | 0.76 [0.63,0.92] | .004 |
| Grade GreadIII vs GreadI | 1.68 [1.38,2.05] | <.001 |
| Grade GreadIV vs GreadI | 1.92 [1.12,3.29] | .018 |
| Surgery Yes vs No | 0.27 [0.23,0.31] | <.001 |
| Chemotherapy Yes vs No/Unknown | 0.64 [0.55,0.74] | <.001 |
| Marital Others vs Married | 1.18 [1.02,1.36] | .025 |
| SEER Regional vs Localized | 1.29 [1.06,1.56] | .010 |
| Tumor_size >=50mm vs <50mm | 1.86 [1.55,2.25] | <.001 |

表内 AJCC_stage IV 也有多因素 HR=3.25 [1.57,6.73], p=.002，但主脚本人工设置的 8 个 `sigvar` 没有 AJCC_stage。不能把人工列表写成“自动严格选择了所有且仅有显著变量”。M_stage=M1 的多因素表项为 `NA (NA-NA, )`。原始 `data.csv` 中 `AJCC_stage==4` 与 `M_stage==1` 指示变量逐行完全相同，这支持模型出现别名/共线性问题的解释；它不是合法估计到的 HR=0。

这些 HR 为项目观察数据中的模型关联结果，不能解释为对治疗干预因果效应的证明。

### LASSO 图

来源：`P/cvlasso.plot.pdf`、`P/lasso.fit.plot.pdf`。两图直接标注 `Optimal Lambda = -5.2590`，但横轴明确为 Log Lambda/对数尺度；这个负数应按**log(lambda)** 解读，不能写成负惩罚强度。由已四舍五入的标签换算 `exp(-5.2590)≈0.0052005`，只是近似换算，不是完整模型对象的精确 lambda 值。

系数路径图图例包含 Age、Chemotherapy、Grade、Marital、Race、SEER-stage、Surgery、Tumor-size 8 个变量。原程序的 LASSO 工作数据也仅在人工 `sigvar` 后进行 LASSO 筛选。这个图不能证明对全部 16 个初始变量完成了同一次自动选择。

### 列线图

来源：`P/Nomogram.pdf`。原图显示 8 个预测变量和 `Pr(Time>1) / Pr(Time>3) / Pr(Time>5)` 概率轴。主脚本 `failtime=c(1,3,5)`，而其他评估明确用 12、36、60 月作为 1、3、5 年。**原列线图不能未经换算就宣称预测 1、3、5 年 OS**；按这套 Time 数值单位，1/3/5 是月尺度数值。视觉上还可见 GreadIII/GreadIV、Race 与治疗标签有局部重叠，适合保留作原始材料并提示单位问题，不适合据图制作精确个人预后计算器。

## 校准曲线：说明和边界

来源：`P/Calibrate_Result/` 下 18 个 PDF，每个图有 1-year、3-year、5-year 三条颜色线，横轴为模型 predicted OS，纵轴为 Observed OS。OS 生存概率的 45 度线是校准参考；它与 DCA 中使用的事件概率 `1-S(t)` 不同。

18 个图的彩色曲线路径几何哈希各不相同；未发现校准曲线完全复制后只改标题的情况。但其数值没有文字标注，不能抽象成一个精确“校准得分”。视觉样本 `Test_Coxph_calibration.pdf` 每个时点仅约 3 个分组点，低概率端和长期误差条较宽；几条线的一部分贴近参考线，不足以证明所有个体概率校准充分。

主脚本 `plot_calibration_gg` 的关键事实：

- 对训练和测试都分别调用 `cph(Surv(Time,Event) ~ model_name, data=data)`，即在输入集合中重新拟合单风险分数的 Cox 包装；测试图属于测试集上重新拟合包装后的分组校准。
- 每个时点 `u=12/36/60`，`cmethod="KM"`，`method="boot"`，`m=nrow(data)/3`，`B=1000`。
- 纵轴使用 `KM.corrected`；误差条为代码中的 `KM.corrected ± 1.96*std.err` 并截断至 0-1。应说明这是原代码构造的误差条，不自动称为完整建模流水线的置信区间。
- 该 bootstrap 包装没有重做原始筛选、LASSO、学习器训练过程，不能作为整个流程的无偏外部验证。
- 18 图含额外的 Train/Test `Lasso_Cox` 校准，但当前 `model_names` 是 8 模型且没有 Lasso_Cox。旧图与当前可见代码的对应关系需要分别说明。

网站可以用它们教“预测 OS 与观察 OS”“长期样本支持”“分组校准与误差条”，应把“测试重新拟合”放在原图旁。

## DCA：说明和边界

来源：`P/DCA_Result/train_DCA_12.pdf`、`train_DCA_36.pdf`、`train_DCA_60.pdf`、`Test_DCA_12.pdf`、`Test_DCA_36.pdf`、`Test_DCA_60.pdf`。

图例包括 Treat All、Treat None、多个模型；训练图文字列出 Coxph，而测试图相应位置列出 Lasso_Cox。当前代码的 DCA 配方含 Coxph、CoxBoost 和其余 6 模型；旧 PDF 的文字图例没有列出 CoxBoost。没有精确数值标签，不能仅靠图像宣称某个阈值的精确净获益。

代码先从已经包装为单变量 Cox 的对象计算 `1-summary(survfit(...), times=time)$surv`，再传给 `dcurves::dca(Surv(Time,Event)~..., time=time)`。这个概率映射和模型对象覆盖问题同样影响 DCA。可解释“阈值概率”“净获益”“Treat All/None 的比较”，但不能从这些历史图给出患者治疗阈值建议。纵轴在图中裁到有限区间，负净获益不能因为部分不可见就当作不存在。

## KM 风险分组：精确标注与方向问题

来源：`P/KM_Result/` 全部 16 图。除测试 SVM 图的 `p=0.053` 外，图上其他 KM 检验文字均为 `p<0.0001`。后者是阈值式报告，不是精确 P 值；训练图部分文字被删失标记或绘图叠加打散，需看原图，不宜逐字 OCR 排版。

| PDF模型名 | 训练初始 high / low | 测试初始 high / low | 测试 Log-rank 原标注 |
| --- | --- | --- | --- |
| CoxBoost | 713 / 714 | 305 / 306 | p<0.0001 |
| GBM | 713 / 714 | 305 / 306 | p<0.0001 |
| Lasso_Cox | 713 / 714 | 305 / 306 | p<0.0001 |
| RSF | 713 / 714 | 305 / 306 | p<0.0001 |
| Survivalsvm | 713 / 714 | 305 / 306 | p=0.053 |
| plsRcox | 713 / 714 | 305 / 306 | p<0.0001 |
| superpc | 703 / 724 | 303 / 308 | p<0.0001 |
| xgboost | 713 / 714 | 305 / 306 | p<0.0001 |

superpc 分组不对半是大量中位数并列时使用 `predictor>median` 的自然结果，不是丢失样本。训练 CoxBoost 和 Lasso_Cox 图的风险表都为 high=(713,148,42,12,0)、low=(714,428,183,63,0)，但整份 PDF 内容并不相同；风险表相同不能证明复制图。

`Test_Survivalsvm_survival.pdf` 中 high 曲线在大部分随访期反而高于 low。其风险表为 high=(305,123,64,24,0)、low=(306,104,40,8,0)，时间点为 0、30、60、90、120。主程序把所有模型预测值较高的组统一叫 high，没有区分“预测生存时间较大”和“风险较高”的方向。网站应明确 SVM 得分需核验方向，不能见 high 标签便称其死亡风险更高。

主程序训练/测试都各自按该集合的中位数重新切组。因此测试图展示的是测试集合自身的中位分层，不能表述成应用训练期固定风险阈值的验证。既有 `蒸馏后的/machine_learning/survival-machine-learning/references/source-audit.md` 也提醒同一问题。

## SHAP：原图内容、尺度与来源限度

来源：`P/SHAP_Result/` 下 23 个 PDF。

全局图包含 RSF、GBM、CoxBoost、LASSO_COX、Superpc、Xgboost、Survivalsvm 各自的 importance bar、beeswarm 和 force；另有 SVM waterfall 与标题为 Partial Dependence 的 16 面板图。当前主程序仅直接保存 SVM 的 5 类绘图文件，旧目录中其他模型 PDF 不应宣称全由这段可见绘图代码同次产生。当前 RData 的读取和对象检查由网站主任务另行负责，本报告不读取并重算学习器。

### 可精确引用的排序与标注

以下是图中明确的特征排序，条形图本身无具体数值标签：

| 原条形图 | 排名前5 |
| --- | --- |
| SHAP_RSF_importance_bar.pdf | Surgery, Tumor_size, AJCC_stage, SEER_stage, Age |
| SHAP_GBM_importance_bar.pdf | Surgery, Tumor_size, AJCC_stage, Grade, Chemotherapy |
| SHAP_CoxBoost_importance_bar.pdf | Surgery, Tumor_size, Chemotherapy, AJCC_stage, Grade |
| SHAP_LASSO_COX_importance_bar.pdf | Surgery, Tumor_size, Chemotherapy, AJCC_stage, Grade |
| SHAP_Superpc_importance_bar.pdf | AJCC_stage, T_stage, SEER_stage, Tumor_size, Surgery |
| SHAP_Xgboost_importance_bar.pdf | Surgery, Tumor_size, AJCC_stage, Grade, SEER_stage |
| SHAP_Survivalsvm_importance_bar.pdf | Surgery, Race, Grade, Chemotherapy, Tumor_size |

SVM bar/beeswarm 图列出当前 8 个特征，其他模型的 bar/beeswarm 多显示 15 个特征名，force 显示“5 个特征 + 11 other features”，16 面板 dependence 图也显示 16 个原始特征。bar 显示 15 行可能是展示截取，不能简单断言其模型恰好只有 15 个特征；但这些含 AJCC_stage/Gender/Income 等特征的图，显然不对应仅 8 个 `sigvar` 的同一份解释矩阵。SVM 的 8 特征全局/force/waterfall 与 16 特征 dependence 图之间也有来源不一致。

force 图的文字精确标注（保留原图有效位数）：

| 原 force PDF | f(x) | E[f(x)] |
| --- | ---: | ---: |
| SHAP_CoxBoost_sv_force.pdf | 0.0507 | 0 |
| SHAP_GBM_sv_force.pdf | 0.193 | 0 |
| SHAP_LASSO_COX_sv_force.pdf | -0.463 | 0 |
| SHAP_RSF_sv_force.pdf | -7.85 | 0 |
| SHAP_Superpc_sv_force.pdf | 0.0782 | 0 |
| SHAP_Survivalsvm_sv_force.pdf | -5.63 | 0 |
| SHAP_Xgboost_sv_force.pdf | -0.171 | -0.628 |

SVM force 图显示：Surgery=0 贡献 -4.08、Grade=1 贡献 -2.99、Race=1 贡献 -2.09、Chemotherapy=1 贡献 +1.33、SEER_stage=2 贡献 +0.777、3 other features 合计 +1.41；主程序指定 `row_id=12`。SVM waterfall 图 `f(x)=5.12`、`E[f(x)]=0`，主程序 `row_id=2`，显示 Surgery=1 +2.43、Race=2 +1.46、Chemotherapy=1 +1.2、Tumor_size=0 +0.955、SEER_stage=1 -0.863、Marital=1 -0.485。图的各贡献经过舍入且可能有近零未标注项，不能要求已显示的几项精确相加等于标注 f(x)。

### 不能把 SHAP 值解释成什么

- 主脚本预测包装的输出不同：RSF 的 `$predicted`、GBM 的 `type="link"`、Coxph 的 `type="risk"`、CoxBoost 的 `type="lp"`、SVM 的 `$predicted`、Superpc 的 `$v.pred`、plsRcox 的 risk，以及 XGBoost 原生 `shapviz`。各图解释的是不同尺度的预测输出，不能跨模型比较 SHAP 条形图长度来比较模型性能。
- 多份 force 图基线为 0，而现有原始预测列的均值/范围并不以 0 为共同概率基线。`fastshap` 部分没有显式设置 `adjust=TRUE`，随后 `shapviz` 未显式传入非零真实预测基线。这些零基线图不能直接称为个体的绝对死亡概率；SVM f(x)=-5.63 尤其不能按负生存时间理解。需要结合保存对象的 baseline 核验解释约定。
- `nsim=100` 是 Monte Carlo 近似参数，不是解释稳定性或置信区间证明；不同模型/变量相关性、类别数值编码都影响解释。
- 条形图 `mean(|SHAP value|)` 没有方向。蜂群图颜色 High/Low 是数值编码高低；Race 的 1/2/3 不是可连续测量的种族高低，不能据颜色讲“种族越大风险越大”。Age 0/1 同理必须显示类别说明。
- 名为 `SHAP_Survivalsvm_Partial_Dependence_plot.pdf` 的图，按原代码是横轴特征、纵轴该特征 SHAP，叠加 `geom_smooth(method="loess")`。它是 **SHAP dependence 散点图**，不是重新干预特征并平均模型预测的标准 PDP。0/1 特征之间的平滑曲线穿过数据不支持的中间类别，不能解释成连续剂量反应；Race/分期等类别同样要按实际水平阅读。
- SHAP 解释模型关联，不提供治疗因果效应证明，也不能单凭 Surgery 排第一认定这是能直接指导临床决策的模型。

## DOCX 和既有蒸馏材料

7 份 DOCX（`P/课程须知.docx`，AUC/Calibrate 的 `读我读我读我.docx`，DCA/KM/ROC/SHAP 的 `1.docx`）都只有同一段课程推广文字，没有技术解释、结果表、数据字典或可学习的模型推导。它们属于原始课程包装材料，网站材料清单可列出；不能把它们当成不同章节的技术教程或摘要来源。

参考过的既有审计来源：

- `蒸馏后的/machine_learning/survival-machine-learning/references/source-audit.md`：指出列线图时间单位、模型覆盖、Lasso 产物与可见拟合块不一致、KM 测试中位数重切等问题。
- `蒸馏后的/machine_learning/survival-machine-learning/references/data-contract.md`：2038 行、18 列，Time/Event 合约和样本量检查。
- `蒸馏后的/machine_learning/_validation/preflight/preflight_report.csv`：65 非正时间、13 重复行等输入检查。
- `蒸馏后的/machine_learning/_validation/original_test_prediction_report.csv`：现有测试 8 模型风险列的缺失、有限值、唯一值检查；这是风险分数结构报告，不能误作模型性能报告。
- `蒸馏后的/machine_learning/_validation/artifact_audit/csv_schemas.csv` 和 `artifact_manifest.csv`：文件结构及来源目录证据。

## 77 个 PDF 的逐类清单

以下路径均相对 `P/`，用于网站索引与覆盖检查。

### 根目录（3）

`cvlasso.plot.pdf`；`lasso.fit.plot.pdf`；`Nomogram.pdf`。

### AUC_Result（4）

`AUC_Result/Train_AUC.pdf`；`AUC_Result/Test_AUC.pdf`；`AUC_Result/Train_C_index.pdf`；`AUC_Result/Test_C_index.pdf`。

### ROC_Result（7）

`ROC_Result/Train_ROC_12.pdf`；`ROC_Result/Train_ROC_24.pdf`；`ROC_Result/Train_ROC_36.pdf`；`ROC_Result/Train_ROC_60.pdf`；`ROC_Result/Test_ROC_12.pdf`；`ROC_Result/Test_ROC_36.pdf`；`ROC_Result/Test_ROC_60.pdf`。

### Calibrate_Result（18）

`Calibrate_Result/Train_Coxph_calibration_ggplot.pdf`；`Calibrate_Result/Train_CoxBoost_calibration_ggplot.pdf`；`Calibrate_Result/Train_GBM_calibration_ggplot.pdf`；`Calibrate_Result/Train_Lasso_Cox_calibration_ggplot.pdf`；`Calibrate_Result/Train_RSF_calibration_ggplot.pdf`；`Calibrate_Result/Train_Survivalsvm_calibration_ggplot.pdf`；`Calibrate_Result/Train_plsRcox_calibration_ggplot.pdf`；`Calibrate_Result/Train_superpc_calibration_ggplot.pdf`；`Calibrate_Result/Train_xgboost_calibration_ggplot.pdf`。

`Calibrate_Result/Test_Coxph_calibration.pdf`；`Calibrate_Result/Test_CoxBoost_calibration.pdf`；`Calibrate_Result/Test_GBM_calibration.pdf`；`Calibrate_Result/Test_Lasso_Cox_calibration.pdf`；`Calibrate_Result/Test_RSF_calibration.pdf`；`Calibrate_Result/Test_Survivalsvm_calibration.pdf`；`Calibrate_Result/Test_plsRcox_calibration.pdf`；`Calibrate_Result/Test_superpc_calibration.pdf`；`Calibrate_Result/Test_xgboost_calibration.pdf`。

### DCA_Result（6）

`DCA_Result/train_DCA_12.pdf`；`DCA_Result/train_DCA_36.pdf`；`DCA_Result/train_DCA_60.pdf`；`DCA_Result/Test_DCA_12.pdf`；`DCA_Result/Test_DCA_36.pdf`；`DCA_Result/Test_DCA_60.pdf`。

### KM_Result（16）

`KM_Result/Train_CoxBoost_survival.pdf`；`KM_Result/Train_GBM_survival.pdf`；`KM_Result/Train_Lasso_Cox_survival.pdf`；`KM_Result/Train_RSF_survival.pdf`；`KM_Result/Train_Survivalsvm_survival.pdf`；`KM_Result/Train_plsRcox_survival.pdf`；`KM_Result/Train_superpc_survival.pdf`；`KM_Result/Train_xgboost_survival.pdf`。

`KM_Result/Test_CoxBoost_survival.pdf`；`KM_Result/Test_GBM_survival.pdf`；`KM_Result/Test_Lasso_Cox_survival.pdf`；`KM_Result/Test_RSF_survival.pdf`；`KM_Result/Test_Survivalsvm_survival.pdf`；`KM_Result/Test_plsRcox_survival.pdf`；`KM_Result/Test_superpc_survival.pdf`；`KM_Result/Test_xgboost_survival.pdf`。

### SHAP_Result（23）

`SHAP_Result/SHAP_CoxBoost_importance_bar.pdf`；`SHAP_Result/SHAP_CoxBoost_importance_beeswarm.pdf`；`SHAP_Result/SHAP_CoxBoost_sv_force.pdf`。

`SHAP_Result/SHAP_GBM_importance_bar.pdf`；`SHAP_Result/SHAP_GBM_importance_beeswarm.pdf`；`SHAP_Result/SHAP_GBM_sv_force.pdf`。

`SHAP_Result/SHAP_LASSO_COX_importance_bar.pdf`；`SHAP_Result/SHAP_LASSO_COX_importance_beeswarm.pdf`；`SHAP_Result/SHAP_LASSO_COX_sv_force.pdf`。

`SHAP_Result/SHAP_RSF_importance_bar.pdf`；`SHAP_Result/SHAP_RSF_importance_beeswarm.pdf`；`SHAP_Result/SHAP_RSF_sv_force.pdf`。

`SHAP_Result/SHAP_Superpc_importance_bar.pdf`；`SHAP_Result/SHAP_Superpc_importance_beeswarm.pdf`；`SHAP_Result/SHAP_Superpc_sv_force.pdf`。

`SHAP_Result/SHAP_Survivalsvm_importance_bar.pdf`；`SHAP_Result/SHAP_Survivalsvm_importance_beeswarm.pdf`；`SHAP_Result/SHAP_Survivalsvm_sv_force.pdf`；`SHAP_Result/SHAP_Survivalsvm_waterfall.pdf`；`SHAP_Result/SHAP_Survivalsvm_Partial_Dependence_plot.pdf`。

`SHAP_Result/SHAP_Xgboost_importance_bar.pdf`；`SHAP_Result/SHAP_Xgboost_importance_beeswarm.pdf`；`SHAP_Result/SHAP_Xgboost_sv_force.pdf`。

## 页面使用建议

指标区默认显示“历史 PDF 标注的 ROC AUC”，显著写出来源文件与普通二元 ROC 口径；单独展示现预测 CSV 的核验差异。C-index 区展示原图与读图解释，不填写未经导出的精确指标。每类结果给出“图上看到了什么、代码怎样得到它、这张图不足以证明什么”三项说明。模型标题与文件名保留原称呼，不能为了 8 模型排版而把 Lasso_Cox 自动改成 Coxph。原始材料、蒸馏改写和本次审计新增的解释应分别标明出处。
