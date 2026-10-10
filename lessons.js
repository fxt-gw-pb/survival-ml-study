/* Teaching notes explain the checked project. Ranges always refer to its original 1,283-line script. */
window.COURSE = {
  groups: [
    {id:'foundation', title:'01 / 数据与研究起点', subtitle:'先读懂数据，再进入模型'},
    {id:'models', title:'02 / 九种模型标签', subtitle:'当前 8 模型 + 历史 Lasso-Cox'},
    {id:'evaluation', title:'03 / 评价与 SHAP', subtitle:'从风险分数到可解释的结果'},
    {id:'practice', title:'04 / 复现与材料审计', subtitle:'把代码、产物和证据对齐'}
  ],
  lessons: [
    {id:'project',group:'foundation',title:'读懂项目与版本',subtitle:'把脚本、数据、图表和保存对象放回同一张地图',minutes:10,tags:['项目结构','版本'],range:[1,49],module:'pang-survml',
      goals:['找到每类材料的用途','区分当前脚本与历史结果','建立从数据到图表的学习路线'],
      sections:[
        {title:'这份项目在做什么',body:`原始课程用 R 为带有随访时间和事件状态的数据建立生存预测模型。主脚本串起：读入数据 → 划分训练 / 测试集 → Cox 筛选与列线图 → LASSO → 八个模型 → 风险分数汇总 → SHAP → AUC、C-index、校准、DCA、ROC、KM。

原始 \`data.csv\` 有 **2,038 行、18 列**，前两列是 \`Time\` 和 \`Event\`，其余是 16 个数字编码特征。保存的训练集有 1,427 行，测试集有 611 行。网站制作过程中没有重新训练这些模型。`},
        {title:'四类材料，四种阅读方式',body:`| 材料 | 用途 | 阅读时先确认 |
|---|---|---|
| 1,283 行原始 R 脚本 | 理解完整流程与对象关系 | 段落位置、当前对象是否被覆盖 |
| 六份原始 CSV | 数据字典、划分、Cox 表和预测分数 | 因子标签、列名、行顺序 |
| 77 份原始 PDF | 检查实际保存的图形 | 模型标签、时间点、图例、版本 |
| 两份 RData | 看保存的模型、SHAP 与 Shiny 对象 | 工作空间版本与可用依赖 |
| 36 个蒸馏模块与参考文档 | 阅读任务拆分及复现原则 | 文档目标是否已由脚本实现 |`},
        {title:'为什么会看到第九个模型',body:`说明文件和当前训练段列出 RSF、GBM、CoxPH、CoxBoost、Survival-SVM、XGBoost、SuperPC、PLS-R Cox 八个模型。历史 PDF 和旧 RData 还保留 **Lasso_Cox**。

旧工作空间的 \`sigvar\` 为 16 个特征、\`rid\` 为 15 个；SHAP 工作空间的这两个对象均为 8 个。不能因为文件位于同一目录，就把它们看成同一次运行的输出。网站为历史图单独保留标签。`},
        {title:'推荐的自学顺序',body:`先完成本组的生存结局、数据编码和划分，再读 CoxPH 与其他模型。理解预测分数的尺度后，学习区分度、校准、DCA、风险分组和 SHAP。最后用材料审计核对每张图能支持什么结论。

每课都有原始代码定位、相关材料、自测和笔记。阅读进度只保存在当前浏览器。`}
      ],quiz:{question:'当前脚本与历史 PDF 的模型标签数不一致，应该如何整理？',options:['把历史 Lasso-Cox 作为版本差异保留','把全部图当成当前八模型的输出','删除多出来的模型后忽略差异'],answer:0,explanation:'保存产物也是项目知识的一部分，但必须说明版本差异，不能编造一致性。'}},
    {id:'survival',group:'foundation',title:'时间、事件与删失',subtitle:'理解 Surv(Time, Event) 以及为什么不能直接做普通分类',minutes:12,tags:['Surv','删失'],range:[50,84],module:'pang-survml-data',
      goals:['理解 Event=0 的含义','统一月与年的换算','发现零随访时间需要单独处理'],
      sections:[
        {title:'每行包含两项结局信息',body:`\`Time\` 是观察到的随访时间，单位为**月**。\`Event=1\` 表示在该时间观察到事件，\`Event=0\` 表示在该时间结束观察但未记录事件。后一种情况属于右删失：我们只知道事件时间晚于已观察时间。

\`Surv(Time, Event)\` 把时间和状态组合成生存结局。这也是 Cox、RSF、GBM、SVM 等模型公式共同的左侧。原始材料使用 OS / 生存标签，网站不进一步推定具体疾病队列。`},
        {title:'36 个月时，一个人到底属于哪一组',body:`| 观察记录 | 对 36 个月结局知道什么 |
|---|---|
| 第 20 个月发生事件 | 已知 36 个月前发生事件 |
| 第 50 个月发生事件 | 已知到 36 个月仍无事件 |
| 第 50 个月删失 | 已知到 36 个月仍无事件 |
| 第 20 个月删失 | 36 个月结局未知，不能直接当作未发生事件 |

这解释了原始 pROC 段为什么需要特别审查：代码把所有 \`Event=0\` 的记录都设为对照，忽略了删失发生在目标时间之前的情况。`},
        {title:'项目数据中要实际看到的数字',body:`原始数据有 **1,224 个事件、814 个删失记录、65 条 Time=0**，没有缺失单元格。零时间并没有因为“无缺失”而自动合法。

原脚本在 LASSO 的局部副本中把非正时间改为 \`0.003\`，但后续训练仍可能使用未修改的表。蒸馏版本的准备脚本提供报错、排除或显式 epsilon 三种处理方式；选择依据应写入分析记录。`},
        {title:'所有时间点用同一个单位',body:`项目大部分评估用 \`12,36,60\` 月，对应 1、3、5 年。列线图原代码却使用 \`failtime=c(1,3,5)\`；在以月为单位的模型中，这实际是 1、3、5 个月。

先统一单位，再讨论模型的“几年生存率”。网页的图谱会按实际文件标出的月数筛选。`}
      ],quiz:{question:'某人在第 20 个月删失，评估 36 个月事件风险时该如何理解？',options:['36 个月结局未知，需要删失处理','直接归入 36 个月未发生事件组','把第 20 个月改成事件时间'],answer:0,explanation:'删失表示观察停止；它不等于在任意更晚的时间点仍无事件。'}},
    {id:'setup',group:'foundation',title:'R 环境与依赖',subtitle:'认清包的角色、安装材料和硬编码路径',minutes:12,tags:['library','CoxBoost','环境'],range:[12,49],module:'pang-survml-environment',
      goals:['区分模型包和绘图包','理解本地 CoxBoost 源码的用途','避免直接运行原始 Windows 路径'],
      sections:[
        {title:'按职责读包清单',body:`| 职责 | 项目中的主要包 |
|---|---|
| 生存对象与 Cox | survival、rms、autoReg、regplot |
| 模型 | randomForestSRC、gbm、CoxBoost、survivalsvm、xgboost、superpc、plsRcox、glmnet |
| 数据划分与整理 | caret、dplyr、tidyr、reshape |
| 评估 | riskRegression、pec、timeROC、pROC、dcurves |
| 解释与图形 | fastshap、shapviz、survminer、ggplot2、ggsci、gridExtra、scales |

主脚本后半段还有新的 \`library()\` 调用。只看开头的清单不能确认依赖齐全。`},
        {title:'先处理路径，再执行代码',body:`第 48 行的 \`setwd()\` 指向作者的 Windows 目录。学习时可以先看代码，真正复现时改成自己的项目路径或使用蒸馏脚本的命令行参数。

一个稳妥的顺序是：记录 R 版本 → 检查包与版本 → 运行输入审计 → 确认各段需要的对象 → 执行指定模块。网页里的“复制代码”用于复制原文，不会自动安装包或运行 R。`},
        {title:'项目附带的安装与源码材料',body:`\`包的安装/\` 中包含 CoxBoost 安装说明、安装脚本、CoxBoost-master 完整源码及 ZIP，还有 \`distr6_1.6.9.tar.gz\`。

材料库保留 \`DESCRIPTION\`、\`NAMESPACE\`、\`R/\`、\`src/\`、\`man/\`，可以继续追踪 \`optimCoxBoostPenalty()\`、\`cv.CoxBoost()\`、\`CoxBoost()\` 和 \`predict.CoxBoost()\`。这些是依赖包附录，主课程讲的是项目怎样调用它们。`},
        {title:'已经验证到了哪里',body:`项目现有 \`_validation/\` 里有输入审计、数据划分、Cox 筛选、CoxPH 和预测表检查的产物。缺少某模型的验证产物时，不能把“有训练脚本”写成“训练已经通过”。本网站保留这些文件供检查。`}
      ],quiz:{question:'原脚本打开后，首先需要确认哪件事？',options:['工作目录与所需依赖是否适配自己的环境','所有 library 调用都可以忽略','直接加载任意 RData 就能复现全部步骤'],answer:0,explanation:'路径、包版本和对象版本都会影响运行；保存对象也不能替代依赖检查。'}},
    {id:'data',group:'foundation',title:'数据字典与编码',subtitle:'16 个特征如何从数字编码变成因子，又如何被读回',minutes:16,tags:['factor','model.matrix','特征'],range:[50,76],module:'pang-survml-data',widget:'dictionary',
      goals:['读懂全部 16 个变量的映射','区分名义类别与有序数字','发现同一项目的两套数据表示'],
      sections:[
        {title:'前两列的位置也是代码契约',body:`说明要求第一列 \`Time\`、第二列 \`Event\`，之后是数字编码自变量。大量代码使用 \`[,3:ncol()]\` 和 \`[,-c(1,2)]\`；仅仅有正确列名仍不够，列顺序改变也可能把结局混进特征。

下面的数据字典直接依据原始 \`factor(levels=...,labels=...)\` 映射。拼写如 \`GreadI\` 保留来源，同时用中文帮助理解。`},
        {title:'因子化解决什么问题',body:`Cox 筛选段把多个变量转换为因子，模型可以相对某个参照水平估计类别效应。之后第 131 行重新读入 CSV，把这些变量恢复成数字编码。

数字 1、2、3 作为一个数值列进入模型，可能产生线性趋势或距离关系；作为类别进入 \`model.matrix()\` 则会展开成对比编码。Race 等多类别变量不能仅因为“编码是数字”就认定它是连续变量。`},
        {title:'当前脚本最终使用的八个特征',body:`\`sigvar=c("Age","Race","Grade","Surgery","Chemotherapy","Marital","SEER_stage","Tumor_size")\`。

原始 \`traindata.csv\` / \`testdata.csv\` 保存的是因子标签表，预测 CSV 对应的训练段则基于再次读入的数字表。材料库可以直接预览每份 CSV 的表头和行，比较这两套表示。`},
        {title:'数据表示也要锁定',body:`项目方法修正文档强调：开发集确定预处理方式，验证集沿用同一套方式。类别水平、展开列的顺序和标准化参数都要可追踪。现有各蒸馏模型脚本并没有统一实现一套共享预处理配方，因此仍需逐个核对输入。`}
      ],quiz:{question:'Race 编码为 1、2、3，是否就可以默认把它当连续变量？',options:['不可以，需要确认变量含义与模型编码','可以，数字编码总是连续变量','只在测试集再转换成因子即可'],answer:0,explanation:'原始映射是 White/Black/Other，编码数字并不表示等距的连续量。'}},
    {id:'split',group:'foundation',title:'划分开发集与验证集',subtitle:'种子 123、70/30 划分与按行拼接的边界',minutes:12,tags:['createDataPartition','seed','验证'],range:[78,84],module:'pang-survml-data',widget:'split',
      goals:['理解按 Event 分层划分','区分内部留出与外部验证','核对记录顺序和重复行'],
      sections:[
        {title:'原代码怎么划分',body:`\`set.seed(123)\` 固定随机数起点。\`caret::createDataPartition(y=data[,"Event"],p=0.7,list=F)\` 用事件状态分层选出训练索引，然后用互补索引组成测试集。

保存结果是训练 **1,427 人 / 851 个事件**，测试 **611 人 / 373 个事件**。事件比例可用于检查分层划分效果，但这个同源留出集应描述为内部验证，不能自动称为外部验证。`},
        {title:'两个准备脚本不等于同一次划分',body:`旧 \`survival-ml-data/scripts/audit_split.R\` 分层抽样使用 \`floor()\`，新 \`pang-survml-data/scripts/prepare_split.R\` 使用 \`ceiling()\`。它们也没有直接调用原始 caret 函数。

即使随机种子都是 123，抽样算法不同，记录集合与顺序仍可能不同。现有 \`_validation/split/validation.csv\` 的 Time/Event 顺序与原始 \`Test_plot_data.csv\` 不同，不能按行合并。`},
        {title:'没有 ID 的重复行意味着什么',body:`输入审计发现原始数据中有 **13 个全行重复**。按因子标签反向编码后，训练和测试合起来能还原原始数据的记录计数；两集也有相同特征与结局的记录。

项目没有患者 ID。相同行值得检查，但仅凭相同变量值不能证明是同一个人，也不能武断宣布患者泄漏。`},
        {title:'开发集负责哪些决定',body:`变量选择、调参、预处理、风险方向、风险到概率的映射以及风险分组切点，都应该在开发阶段确定。验证集负责评估已经固定的预测。

这一原则会在校准、DCA 和 KM 章节反复用到。`}
      ],quiz:{question:'同样使用 seed=123 的两种抽样脚本，是否保证按行完全对应？',options:['不保证，抽样算法与顺序也要一致','保证，随机种子相同就足够','只要行数相同就可以直接 cbind'],answer:0,explanation:'种子并不能消除抽样算法、取整规则和输出顺序的差异。'}},
    {id:'screen',group:'foundation',title:'单因素与多因素 Cox',subtitle:'从 autoReg 输出读 HR、置信区间和筛选规则',minutes:15,tags:['coxph','HR','autoReg'],range:[88,105],module:'pang-survml-cox-screen',widget:'cox-table',
      goals:['读懂 HR 和参照组','发现 sigvar 是人工指定','核对当前筛选表与后续训练'],
      sections:[
        {title:'原代码使用训练集筛选',body:`\`coxph(Surv(Time,Event)~.,data=rt)\` 用除结局以外的列构建 Cox 模型。随后 \`autoReg()\` 输出单因素与多因素结果；源码注释写明以单因素 P<0.05 进入多因素分析。

调用中出现 \`milti=TRUE\`。应核对所用 autoReg 版本的参数，不能把这段文字无条件当作已成功执行的保证。`},
        {title:'读 HR 时必须带上参照',body:`HR 是在模型假设下的相对风险率。类别项需要相对参照水平理解，95% CI 表示估计的不确定性，P 值只回答该模型中的统计检验。

保存表有 41 行，含类别水平、人数和估计结果。网站可直接预览原表；空单元格与参考水平不应当补成编造的数字。`},
        {title:'sigvar 不是自动生成的筛选结论',body:`第 102 行直接写入八个变量。注释还允许在多因素显著变量少时使用单因素变量。这是人工决策步骤，并非根据输出表程序化提取。

现存表中 AJCC_stage IV 也有多因素显著项，但 sigvar 没有纳入 AJCC_stage。教学时应分别描述“表中筛选结果”和“脚本最终指定的特征”，不能把列表写成自动提取了全部显著变量。`},
        {title:'蒸馏版本增加了什么',body:`\`cox_screen.R\` 显式导出单因素与多因素表、\`cox.zph()\` 比例风险假设检查和模型 RDS。它拟合传入的全部 vars，**并没有自动按单因素 P<0.05 筛选**。

已有验证 CSV 能说明这些文件曾产出，但不能替代预处理与选变量理由。新版验证使用八个数字编码特征，每列只有一个系数，多类别变量没有自动展开为因子；不能与原始分类表视为同一模型。

新版 PH 表的 GLOBAL χ²=104.7449、df=8、p≈4.5624e-19，提供明显的比例风险假设诊断信号。它是模型诊断，不能因为某个 HR 显著就忽略。原始数据的 AJCC_stage==4 与 M_stage==1 指示逐行相同，保存原表的 M1 多因素估计为 NA，也应核对共线性。`}
      ],quiz:{question:'sigvar 中的八个变量是否就是脚本自动提取的多因素显著变量？',options:['不是，它们在源码中被直接指定','是，变量名来自自动读取的 CSV','只要做过 autoReg 就一定是'],answer:0,explanation:'代码写的是明确的字符向量；保存表和该向量也存在差异。'}},
    {id:'nomogram',group:'foundation',title:'列线图与相对风险',subtitle:'regplot、risk 分数以及 1/3/5 的时间单位',minutes:12,tags:['regplot','Nomogram','risk'],range:[106,126],module:'pang-survml-nomogram',gallery:{family:'列线图'},
      goals:['找到列线图模型的输入','区分相对风险和生存概率','检查 failtime 的单位'],
      sections:[
        {title:'先拟合 Cox，再画列线图',body:`\`fmla\` 把八个 sigvar 用加号拼成公式；\`res.cox=coxph(fmla,data=traindata)\` 得到模型。此时 traindata 仍是因子标签版本。

\`regplot()\` 使用 density / boxes 显示变量分布，显示积分与垂线，并按 \`rank="sd"\` 排序。查看原图时，可沿变量取值、积分轴和概率轴逐层理解。`},
        {title:'predict(type="risk") 不直接给几年概率',body:`\`Nomo_train$Nomogram\` 和 \`Nomo_test$Nomogram\` 来自 \`predict(res.cox,type="risk")\`，是模型的相对风险尺度。

在 Cox 结构下，线性预测值 LP 与相对风险有关：**risk = exp(LP)**。指定时间的生存概率还需要基线生存函数与正确的中心化约定，不能把 risk 当作 0 到 1 的事件概率。`},
        {title:'项目中实际存在的单位问题',body:`原代码写 \`failtime=c(1,3,5)\`，输入时间却是月。保存图的 1/3/5 时间点应按这个代码事实审查，不能直接冠以“1、3、5 年”。

蒸馏的 \`fit_nomogram.R\` 接受显式时间参数，可使用 \`12,36,60\`。其实际运行和其他依赖仍需检查，不能因为提供了脚本便认为已验证。`}
      ],quiz:{question:'输入 Time 单位是月，要表示 1、3、5 年应设置什么时间点？',options:['12,36,60','1,3,5','0.1,0.3,0.5'],answer:0,explanation:'模型的预测时间与 Time 必须使用同一个单位。'}},
    {id:'lasso',group:'foundation',title:'LASSO 筛选与交叉验证',subtitle:'glmnet、lambda.min、非零系数和两张路径图',minutes:18,tags:['glmnet','lambda.min','CV'],range:[129,254],module:'pang-survml-lasso',gallery:{family:'LASSO'},
      goals:['读懂 alpha=1 和 family=cox','理解两张 LASSO 图','核对 rid 是否进入后续模型'],
      sections:[
        {title:'这一段筛选的输入是什么',body:`第 140 行用训练集的 Time、Event 和 sigvar 构建 lasso_data。\`x1\` 为特征矩阵，\`x2\` 为生存结局；\`glmnet(family="cox",alpha=1)\` 拟合 Cox 的 L1 惩罚路径。

\`cv.glmnet()\` 估计交叉验证表现。\`coef(cvfit,s="lambda.min")\` 返回使平均交叉验证误差最小的惩罚水平对应系数；非零项组成 \`rid\`。`},
        {title:'两张图回答不同问题',body:`系数路径图横轴是 log(lambda)，展示每个变量的系数随惩罚强度改变。交叉验证图纵轴是 Partial Likelihood Deviance，展示误差及波动，虚线标出选择的惩罚水平。

代码用 log(lambda.min) 构建图中的标签，不能把这一数值直接当作 lambda 本身。蒸馏版本另导出 \`lambda.1se\` 的系数，用于比较更简约的选择。`},
        {title:'筛选做了，后续却仍用 sigvar',body:`第 253、254 行保留 \`c("Time","Event",sigvar)\`。注释说若要使用 LASSO 筛选结果，应把 sigvar 改为 rid。

所以当前脚本不能简单概括成“LASSO 选完变量后训练全部模型”。它计算了 rid，但默认仍使用人工指定变量。旧 RData 的 15 特征 rid 与 SHAP RData 的 8 特征 rid 也属于不同版本。`},
        {title:'零时间和类别展开要在同一流程处理',body:`原始 LASSO 把局部 Time<=0 改为 0.003，数值特征直接 \`as.matrix()\`。新模块要求先解决非正时间，并使用 \`model.matrix()\`。

如果输入还是数字编码，model.matrix 不会自动猜出哪些列应为因子。要先确定变量类型，再建立开发与验证一致的矩阵。`}
      ],quiz:{question:'代码算出 rid 后，当前默认训练段实际保留哪组变量？',options:['sigvar','必然是 rid','所有 16 个原始特征'],answer:0,explanation:'第 253、254 行仍明确使用 sigvar，改成 rid 需要显式编辑。'}},
    {id:'coxph',group:'models',title:'Cox 比例风险模型',subtitle:'最清晰的基线：线性预测值、相对风险和比例风险检查',minutes:14,tags:['coxph','LP','PH'],range:[288,291],module:'pang-survml-coxph',gallery:{family:'校准',model:'CoxPH'},
      goals:['理解公式中的全部变量','区分原始 risk 与蒸馏 lp','找到比例风险检查产物'],
      sections:[
        {title:'原始训练段只有四行',body:`\`Coxph=coxph(Surv(Time,Event)~.,traindata)\`。\`~.\` 使用数据中剩余的所有预测变量，此时表已经被缩减为八个 sigvar 的数字编码。

Cox 结构把风险率表示成基线风险率乘以 exp(线性预测值)。它是相对风险模型，时间基线与协变量作用被区分开来。多类别编码的含义仍取决于训练时的数据类型。`},
        {title:'输出尺度要写在列名旁',body:`原始预测用 \`type="risk"\`；蒸馏 \`train_coxph.R\` 使用 \`type="lp"\`。二者都可以用来表达风险排序，但数值尺度不同，不能直接比较或混拼。

原始 \`Coxph\` 分数也会在后续被用作单变量 Cox 适配器的输入，算法对象名称随后被覆盖。读评估代码时要沿时间顺序跟踪这个变化。`},
        {title:'已有模块与检查边界',body:`蒸馏脚本在开发集拟合，用同一模型预测两集，导出 \`ph_test.csv\` 和 \`coxph_model.rds\`。现有 _validation 里确有这些结果。

\`cox.zph()\` 用于检查比例风险假设；它不是一个模型优劣总分。模型矩阵编码、拟合条件与实际研究假设需要一起解释。`}
      ],quiz:{question:'原始 Coxph 列与蒸馏 Coxph 列分别使用 risk 与 lp，如何处理？',options:['注明尺度，保持各自版本完整','按行覆盖成同一列即可','二者数字必然相同'],answer:0,explanation:'尺度和输入版本不同，不能仅凭相同模型名混用。'}},
    {id:'rsf',group:'models',title:'随机生存森林 RSF',subtitle:'1000 棵树、logrank 分裂与 mortality 分数',minutes:14,tags:['rfsrc','ntree','logrank'],range:[260,271],module:'pang-survml-rsf',gallery:{family:'KM',model:'RSF'},
      goals:['读懂主要超参数','找到 predicted 的真实用途','避免把森林分数当作概率'],
      sections:[
        {title:'原始参数逐项阅读',body:`| 参数 | 原值 | 在这段代码中的作用 |
|---|---|---|
| ntree | 1000 | 森林树数 |
| nodesize | 3 | 末端节点大小控制 |
| mtry | 2 | 每次分裂候选变量数 |
| splitrule | logrank | 生存结局的分裂准则 |
| importance | TRUE | 保留变量重要性 |
| proximity / forest | TRUE | 保存接近度 / 森林 |
| seed | 123 | 随机状态 |

原注释建议调整 nodesize，但这段本身没有执行参数搜索。`},
        {title:'模型输出的是风险排序分数',body:`项目调用 \`predict(RSF,newdata)$predicted\` 并转成 numeric。这里的森林 mortality / 风险分数不是某个特定月的事件概率。

固定时间的生存函数和这个标量分数是不同的预测对象。原始评估段后来用分数拟合 Cox 适配器，再得到时间概率，应单独标明这一步。`},
        {title:'蒸馏版本能做与不能做的事',body:`新脚本保留 1000 棵树、nodesize=3、logrank；mtry 改成特征数平方根的向下取整，导出重要性、两集分数和 RDS。

它仍没有自动执行 nodesize / mtry 的交叉验证搜索。参数“有建议调整”与“已经优化”是两件事。原始 RSF 的 SHAP 图和保存对象还存在 8 与 16 特征差异，要核对版本。`}
      ],quiz:{question:'RSF 的 $predicted 能直接输入要求 36 月事件概率的 DCA 吗？',options:['需要先获得并验证相应时间的概率','可以，它总在 0 到 1 之间','除以最大分数即可'],answer:0,explanation:'标量 mortality 分数与指定时间的绝对事件风险不同。'}},
    {id:'gbm',group:'models',title:'梯度提升生存模型 GBM',subtitle:'coxph 损失、学习率与应该选择的树数',minutes:14,tags:['gbm','shrinkage','n.trees'],range:[274,283],module:'pang-survml-gbm',gallery:{family:'SHAP',model:'GBM'},
      goals:['理解主要训练设置','识别固定树数和 CV 的关系','理解 link 分数'],
      sections:[
        {title:'逐步叠加树来拟合 Cox 损失',body:`原代码 \`distribution="coxph"\`、\`n.trees=1000\`、\`interaction.depth=5\`、\`n.minobsinnode=3\`、\`shrinkage=0.01\`。

深度控制树的交互表达，学习率控制每次提升的步长。代码还设置 10 折 CV 和 6 核，但预测直接指定 1000 棵树，没有从 CV 结果选最优树数。`},
        {title:'预测和 SHAP 的同一尺度',body:`训练与测试的预测，以及 \`pred_GBM\` 包装器，均使用 \`type="link",n.trees=1000\`。SHAP 因而解释的是这个 link 分数，而非“36 个月死亡概率”。

读取图时，变量贡献正负与目标分数含义要对应，重要性条形图只能比较影响大小，不能单独判断方向。`},
        {title:'现有模块改动',body:`蒸馏脚本把候选树数上限设为 3000，并用 \`gbm.perf(method="cv")\` 选择 best_trees。它保存 \`model\` 与 \`best_trees\`，预测时使用选择结果。

这是代码中可见的修改，不代表项目目录已经包含这版 GBM 的训练或验证产物。`}
      ],quiz:{question:'原始 GBM 设置 cv.folds=10 后，预测是否自动用了 CV 最优树数？',options:['没有，预测仍指定 n.trees=1000','有，设置 CV 就会自动选择','无法再预测训练集'],answer:0,explanation:'必须显式从 CV 得到并使用最佳树数，原代码没有这一步。'}},
    {id:'coxboost',group:'models',title:'CoxBoost',subtitle:'从 penalty 优化到 optimal.step，再到线性预测值',minutes:15,tags:['penalty','stepno','CoxBoost'],range:[295,305],module:'pang-survml-coxboost',gallery:{family:'SHAP',model:'CoxBoost'},
      goals:['跟踪三个训练调用','理解惩罚与步数选择','用包源码继续追踪'],
      sections:[
        {title:'三步训练，三个对象',body:`1. \`optimCoxBoostPenalty()\`：起始 penalty=200，优化惩罚，结果存在 pen。
2. \`cv.CoxBoost()\`：maxstepno=200、K=3、type="verweij"，选择最优提升步数。
3. \`CoxBoost()\`：用 pen$penalty 和 cv.res$optimal.step 拟合最终模型。

特征通过 \`as.matrix(traindata[,-c(1,2)])\` 输入，列顺序必须固定。`},
        {title:'lp 包装器为何需要不同参数',body:`原预测调用传入 newtime / newstatus，并指定 \`type="lp"\`。SHAP 包装器给这些参数放入长度匹配的常数向量，同样取线性预测值。

解释目标是 LP。无需为了“解释某个时间的风险”而误认为常数 newtime=1 代表已经在做一年概率预测。`},
        {title:'模块与源码附录',body:`新训练脚本把交叉验证折数改为 10，其余调用结构相近，导出开发 / 验证分数与载荷。项目本地包源码中包含 penalty 优化、交叉验证、重抽样与预测方法，材料索引可以按函数名搜索。

本课既保留原始参数，也明确它们是课程设置；没有当前项目外的模型排名推荐。`}
      ],quiz:{question:'CoxBoost 最终 stepno 来自哪里？',options:['cv.res$optimal.step','固定为 start.penalty=200','测试集的 KM 最优切点'],answer:0,explanation:'惩罚先优化，提升步数由训练内交叉验证结果选择。'}},
    {id:'svm',group:'models',title:'Survival-SVM',subtitle:'lin_kernel、优化参数与需要确认的分数方向',minutes:13,tags:['survivalsvm','kernel','direction'],range:[311,322],module:'pang-survml-survivalsvm',gallery:{family:'SHAP',model:'Survivalsvm'},
      goals:['认清原始参数','检查 predicted 的方向','避免把 SHAP 正值一律解释为更高死亡风险'],
      sections:[
        {title:'原始调用完整设置',body:`gamma.mu=0.5，opt.meth="quadprog"，diff.meth="makediff3"，kernel="lin_kernel"，sgf.sv=5，sigf=7，maxiter=100，margin=0.1，bound=10。

这些是给定训练配置，源码没有内层参数搜索。预测取 \`$predicted\`；网站保留完整调用供逐项查包说明。`},
        {title:'方向要从开发数据核对',body:`不同算法的 predicted 可能代表不同尺度或排序含义。SVM 分数尤其不能只按列名断言“越大越危险”。项目文档要求在开发阶段确认风险方向。

原 pROC 会自动选择方向，因此看见 AUC>0.5 也不能证明全套 KM、C-index 和 SHAP 已使用同一风险方向。`},
        {title:'SHAP 与模型尺度相连',body:`\`pred_Survivalsvm()\` 返回 numeric predicted。蜂群图、力图、瀑布图和依赖图都在解释这个标量输出。

若它的方向尚未确认，正贡献只能表述为“增加模型输出”。条形重要性取平均绝对贡献，连正负方向也被去掉了。`},
        {title:'现有模块没有自动标准化',body:`蒸馏训练脚本仍使用固定参数，也没有写入只在训练集拟合的标准化步骤。文档中的规范要求并不能当成脚本已经完成的功能。`}
      ],quiz:{question:'SVM SHAP 为正，能否直接写“增加死亡风险”？',options:['先确认输出的尺度与风险方向','可以，所有模型 SHAP 的方向相同','只要条形重要性高就可以'],answer:0,explanation:'SHAP 的正负是相对其解释目标；目标含义要先明确。'}},
    {id:'xgboost',group:'models',title:'XGBoost 的 Cox 目标',subtitle:'有符号生存标签与 early stopping 的验证数据',minutes:15,tags:['survival:cox','DMatrix','early stopping'],range:[327,345],module:'pang-survml-xgboost',gallery:{family:'SHAP',model:'XGBoost'},
      goals:['理解事件与删失标签符号','识别训练集自我早停','区分预测分数与原生 SHAP 的尺度'],
      sections:[
        {title:'标签符号编码删失',body:`\`ifelse(Event==1,Time,-Time)\`：事件时间为正，删失时间为负，再构建 xgb.DMatrix。Time=0 在这套规则中丢失符号区分，所以必须先确定零时间处理。

原参数 objective="survival:cox"、booster="gbtree"、eval_metric="cox-nloglik"、eta=0.03、max_depth=3、subsample=1、colsample_bytree=1、gamma=0.5。`},
        {title:'原来的早停没有独立验证',body:`原代码 nrounds=100、early_stopping_rounds=50，watchlist 的 val2 却仍是 traindata_matrix。这是在训练数据上监控，不是独立的验证表现。

新脚本从开发集划出 80% / 20% 的内层训练与验证，设上限 2000 轮，用内层验证进行早停，并保持外层验证集独立。其选中轮数和最终训练范围仍应记录。`},
        {title:'原生 SHAP 和预测值要核对尺度',body:`原始 SHAP 使用 \`shapviz(xgboost,X_pred=X_train_matrix)\`，而不是 fastshap 包装器。解释图对应原生贡献值输出；应核对它与预测响应、margin 的尺度关系。

不能把 SHAP 数值直接解释成死亡概率百分点，也不能拿 XGBoost 的 SHAP 绝对值与 RSF mortality 的 SHAP 绝对值直接排名。`}
      ],quiz:{question:'watchlist 把训练矩阵命名为 val2，它就成为验证集了吗？',options:['没有，数据本身仍是训练集','是，名称决定数据作用','只要 early_stopping_rounds>0 就是外部验证'],answer:0,explanation:'验证独立性取决于数据来源，与对象名无关。'}},
    {id:'superpc',group:'models',title:'监督主成分 SuperPC',subtitle:'转置特征矩阵、阈值扫描与最后固定的一个成分',minutes:15,tags:['superpc','threshold','components'],range:[348,365],module:'pang-survml-superpc',gallery:{family:'SHAP',model:'SuperPC'},
      goals:['理解 x 的特征×样本方向','追踪 threshold 的选择','辨别可搜索与最终使用的成分数'],
      sections:[
        {title:'与普通数据表相反的矩阵方向',body:`SuperPC 的 list 需要 x、y、censoring.status 和 featurenames。原代码将特征表转置，所以 **x 的行是特征，列是样本**。

开发与测试 list 要保留一致的变量名和顺序。y 用 Time，censoring.status 用 Event。`},
        {title:'CV 搜索阈值，最终使用一个成分',body:`训练 type="survival"、s0.perc=0.5。CV 设置 20 个 threshold、10 折、最多 3 成分、min.features=5。

预测的 threshold 来自 \`thresholds[which.max(scor[1,])]\`，n.components=1。虽然 CV 允许三个成分，最终代码仍只取第一成分的最佳阈值，不能写成“自动挑选了最佳成分数”。`},
        {title:'包装器依赖训练背景对象',body:`SHAP 的 pred_Superpc 闭包引用 superpc_fit、traindata_superpc 和 superpc CV 对象。它构造新特征 list，用占位 y / status 进行预测，再取 v.pred。

原始脚本含该包装器；当前通用 \`explain_score.R\` 没有 SuperPC 分支。因此不能认为所有模型可直接走同一个蒸馏 SHAP 接口。`}
      ],quiz:{question:'原始 SuperPC 最终预测用了几个成分？',options:['1 个','由 n.components=3 自动决定为 3 个','与样本量一样多'],answer:0,explanation:'CV 的候选上限与最终 superpc.predict 的参数不同。'}},
    {id:'plsrcox',group:'models',title:'PLS-R Cox',subtitle:'交叉验证做过以后，nt 是否真正来自选择结果',minutes:13,tags:['plsRcox','nt','CV'],range:[368,373],module:'pang-survml-plsrcox',gallery:{family:'KM',model:'PLS-R Cox'},
      goals:['理解成分数参数','发现固定 nt=3','跟踪个体预测所需的基线'],
      sections:[
        {title:'原始程序的两次调用',body:`\`cv.plsRcox(...,nt=10,nfold=10)\` 先进行交叉验证，结果放在 cv.plsRcox.res。随后 \`plsRcox(...,nt=3)\` 直接拟合三个成分。

代码没有读取交叉验证结果中的最佳成分数。因此这份输出应描述为 nt=3 的模型，不能声明已使用 CV 最佳 nt。`},
        {title:'预测列和保存对象',body:`预测使用 \`type="risk"\`、输入特征矩阵，分别写入训练与测试分数。旧工作空间和 SHAP 工作空间的特征集合不同，保存的 plsRcox 不应跨版本交换。

个体生存概率还需要基线生存数据。保存的 Shiny server 使用另一个 plsRcox_base 对象做变换，这部分不在当前主脚本里。`},
        {title:'现有修正仍有回退分支',body:`新 train_plsrcox.R 尝试使用 cv$nt.opt，否则回退 3L。必须检查实际包返回结构，才能说明是否真正采用了 CV 结果。

新载荷保存 model / cv / nt / predictors，却没有自动保存个体预测页面所需的 baseline_survival。提供 app 生成器不等于已经拥有可验证的概率预测应用。`}
      ],quiz:{question:'原始 cv.plsRcox 计算后，最终模型 nt 取什么？',options:['代码固定为 3','自动取交叉验证的最佳值','固定为 10'],answer:0,explanation:'最终拟合调用显式写 nt=3，CV 对象没有被用于该参数。'}},
    {id:'lasso-cox',group:'models',title:'历史 Lasso-Cox 模型',subtitle:'区分变量筛选、惩罚模型与保存产物中的旧标签',minutes:12,tags:['历史版本','Lasso_Cox','glmnet'],module:'pang-survml-lasso-cox',gallery:{family:'KM',model:'Lasso-Cox'},
      goals:['区分 LASSO 筛选与 Lasso-Cox 预测','理解旧工作空间的对象类','准确引用历史结果'],
      sections:[
        {title:'当前训练段没有这个对象',body:`主脚本里有 glmnet 的 LASSO 筛选，但当前八模型段没有 \`Lasso_Cox\` 训练。原始预测 CSV 的八列含 Coxph，不含 Lasso_Cox。

历史校准、KM、ROC 和部分 SHAP 图却有 Lasso_Cox 标签，旧 RData 中 Lasso_Cox 的对象类是 **coxph**。仅凭标签不能断定它就是 glmnet 惩罚模型本身，可能涉及筛选后重新拟合，需要从保存对象继续核对。`},
        {title:'现有专门模块的实现',body:`\`train_lasso_cox.R\` 在开发集生成 model.matrix，用 cv.glmnet(family="cox",alpha=1)，取 lambda.min 的 link 预测；保存 cv 模型、矩阵 terms 和变量名。

这是一份明确的惩罚 Cox 实现，但不是证明历史图按这份新脚本生成的证据。历史数值和新算法定义在网站中分别标注。`},
        {title:'看历史图时保留不确定性',body:`ROC PDF 中 GBM、RSF、Lasso_Cox 可能显示相同的三位小数 AUC。相同的舍入值不代表曲线、预测排序或模型对象相同。

网站保留这些图与标签，并指出图例与现存 CSV 的差异；不补造缺失的 Lasso_Cox 预测列。`}
      ],quiz:{question:'旧 RData 的 Lasso_Cox 类为 coxph，这能证明它是当前 glmnet 模型吗？',options:['不能，需进一步核对版本与拟合过程','能，模型名比对象类更可靠','可以直接替换 Coxph 列'],answer:0,explanation:'模型名、类和训练过程必须相互印证。'}},
    {id:'predictions',group:'evaluation',title:'预测表与模型对象',subtitle:'cbind 的对齐前提、分数尺度与对象覆盖',minutes:15,tags:['cbind','risk score','适配器'],range:[381,401],module:'pang-survml-predictions',widget:'predictions',
      goals:['读懂完整八列预测输出','区分 score 与 horizon risk','发现模型名被 Cox 适配器覆盖'],
      sections:[
        {title:'每行是一条记录的八个输出',body:`Train_plot_data.csv 有 1,427 行，Test_plot_data.csv 有 611 行；它们均有 Time、Event、Coxph、CoxBoost、RSF、GBM、Survivalsvm、xgboost、superpc、plsRcox 十列。

原代码逐个 cbind 分数，依赖所有预测表的行顺序完全相同。它没有 ID 可以做显式键连接。`},
        {title:'风险分数不能统一叫概率',body:`| 输出 | 原代码尺度 |
|---|---|
| Coxph | predict(type="risk") 相对风险 |
| CoxBoost | LP |
| RSF | predicted mortality / 标量分数 |
| GBM | link |
| Survival-SVM | predicted，方向需核对 |
| XGBoost | Cox 目标预测响应，需核对接口尺度 |
| SuperPC | v.pred |
| PLS-R Cox | type="risk"，需核对定义 |

蒸馏接口用 \`Model__risk__36\` 一类列名表示特定时间的事件概率；普通 score 列不满足这个接口。`},
        {title:'同一个名字后来变成另一种模型',body:`第 664 行之后，RSF、GBM、Coxph 等变量被重新赋值为 \`coxph(Surv(Time,Event)~模型分数)\`。原来的森林 / 提升模型对象被覆盖为单分数 Cox 适配器。

测试 AUC 段又为多个模型在测试集拟合适配器，并继续覆盖部分名称。这会让后续 C-index 和 DCA 混入不同拟合来源。修正文档要求将算法对象与适配器分开命名。`},
        {title:'预测表检查已经做了什么',body:`现有 validate_predictions.R 检查缺失、非有限值、常量列和 __risk__ 列的 [0,1] 范围。它不能证明行已按患者 ID 对齐，也不能证明概率完成了正确校准。

验证输出中的行数、唯一值和范围是必要检查，不是完整研究验证。`}
      ],quiz:{question:'两份分数表行数相同，是否足以直接 cbind？',options:['不足，还要确认同一记录及相同行顺序','足够，模型名称不同即可','只需 Time 最大值相同'],answer:0,explanation:'不同数据划分也可能有相同行数；按行拼接必须先有记录对应关系。'}},
    {id:'auc',group:'evaluation',title:'时间依赖 AUC',subtitle:'riskRegression::Score 的时间序列与测试集重新拟合',minutes:15,tags:['Score','timeROC','IPCW'],range:[655,747],module:'pang-survml-time-auc',gallery:{family:'时间 AUC'},
      goals:['理解 AUC(t) 与时间点','跟踪原始适配器的来源','区分原始图与新 timeROC 接口'],
      sections:[
        {title:'AUC 随时间变化',body:`时间依赖 AUC 在每个目标时间比较风险排序的区分能力，同时需要处理删失。原代码用 riskRegression::Score(metrics="AUC",times=seq(0,70,5))，再画模型随时间的曲线。

图上 0.7 的虚线是展示参照线；它不是项目外的临床适用标准。时间越晚，在险样本更少，不确定性更需要检查。`},
        {title:'原图评价的是 Cox 适配器',body:`原代码先把每列模型分数拟合成一个单变量 Cox，再交给 Score。测试段还在 testplot_data 上重新拟合适配器。

因此测试 AUC 图应按“测试分数的重新拟合后评估”理解，不能不加说明地当成完全固定的训练模型外推结果。`},
        {title:'修正接口及其边界',body:`time_auc.R 直接对 score 列调用 timeROC，采用 marginal 权重和 iid=TRUE，输出 time_auc.csv 与图。它需要风险方向一致、时间点有效。

现有源码没有对所有非法输入、过晚时间或缺失方向自动处理。新接口的结果也不是原始 PDF 曲线的复算证明。`},
        {title:'没有数值表时不编造精确读数',body:`原始 AUC / C-index 折线 PDF 主要保存曲线与坐标，没有每个时间点的数值表。网站展示高清原图，不从曲线目测出三位小数的“精确结果”。`}
      ],quiz:{question:'原始测试 AUC 段在测试集重新拟合分数到 Cox 的映射，会影响什么？',options:['使评估不再是完全固定预测的验证','只是改了图颜色','保证一定是真正外部验证'],answer:0,explanation:'模型或映射从验证结局中学习信息，解释评估时必须说明。'}},
    {id:'cindex',group:'evaluation',title:'C-index 与风险方向',subtitle:'pec::cindex 的时间曲线不等于一个全局 concordance 数',minutes:13,tags:['concordance','pec','C-index'],range:[751,814],module:'pang-survml-cindex',gallery:{family:'C-index'},
      goals:['理解成对排序','区分全局与时间依赖指标','核对对象覆盖对评估的影响'],
      sections:[
        {title:'C-index 看可比较记录的排序',body:`C-index 评价风险排序与观察到的生存时间顺序是否一致，删失决定哪些记录对可比较。一个全局 concordance 和指定时间序列的 C-index 不是可随意互换的同一结果。

原程序使用 pec::cindex(eval.times=seq(0,70,5))，把 AppCindex 整理为长表画图。`},
        {title:'风险越大与生存越长要统一',body:`若某接口默认更大的预测值表示更长生存，直接输入“越大越危险”的分数会反转方向。蒸馏脚本全局 concordance 段对分数取负号。

这个约定必须先核对每个模型；不能对一个方向未知的 SVM 分数机械套用。`},
        {title:'原始调用使用了被覆盖的对象',body:`训练 C-index 出现在测试 AUC 段之后。由于部分 xgboost / superpc / plsRcox 名称已经在测试段被覆盖，当前环境中的对象未必都由训练集拟合。

学习时应在代码阅读器跳转到第 664、709、752、785 行，跟踪每个对象最近一次赋值。它比单看图名更可靠。`},
        {title:'新脚本明确保留开发适配器',body:`cindex.R 在开发分数表拟合适配器，再应用到验证表；另输出验证全局 C-index、标准误及区间。这改善了对象来源的清晰度，但风险方向和输入完整性仍需审查。`}
      ],quiz:{question:'图名写 Train_C_index，是否足以证明所有适配器都只在训练集拟合？',options:['不足，需要跟踪传入对象最近的赋值','足够，文件名就是证明','只需要检查 ylim'],answer:0,explanation:'原程序在此前已覆盖部分对象，文件名无法证明对象来源。'}},
    {id:'roc',group:'evaluation',title:'固定时间 ROC 与删失',subtitle:'读原始 AUC / 95% CI，同时发现普通分类转换的漏洞',minutes:17,tags:['pROC','timeROC','ROC'],range:[988,1190],module:'pang-survml-roc',gallery:{family:'ROC'},widget:'roc-values',
      goals:['追踪 Result 的构造','读懂历史 PDF 图例','区分精确标注与可复核 CSV 结果'],
      sections:[
        {title:'原始 pROC 把谁当成阳性',body:`代码先分开 Event=1 与 Event=0。事件组用 Time<=目标月判断 Result=1，其余为 0；所有删失记录被设置为 Result=0，再合并做普通二元 ROC。

这错误地把目标时间前已删失的人当成对照。它也不同于处理删失的时间依赖 ROC，不能只把两种指标都简称“AUC”而忽略定义。`},
        {title:'历史图中实际标注的数字',body:`原 ROC PDF 的图例含 AUC 和 95% CI，下表逐字提取这些数值，标为**历史 PDF 原标注**。有的文件名为 Train，内部标题却写 Testset；部分图例还存在色样与文字错位。

项目多份 PDF 中 GBM、RSF、Lasso_Cox 的 AUC 恰好相同到三位小数。这不能证明模型或曲线相同。`},
        {title:'现存预测 CSV 与历史图并非同一次可对齐产物',body:`按原二元 Result 规则，从已保存预测 CSV 做秩比较，不重新训练模型，得到的 AUC 与历史 PDF 有明显差异。例如测试 12 月 CSV 的 RSF 约 0.8186，PDF 标为 0.828；训练 12 月 CSV 的 RSF 约 0.8442，PDF 标为 0.879。

这些复核值只是说明材料版本不一致。它们仍继承了原二元删失定义，不能被包装为修正后的有效生存 AUC。`},
        {title:'改用生存 ROC 后还需验证实现',body:`修正文档建议 IPCW 的 timeROC。现有 time_roc.R 取 o$AUC[1]、FP[,1]、TP[,1]，单时间调用时应核对返回的 times 与列索引，避免读取自动补入的零时间列。

因此网站区分“应采用的方法”与“现有脚本仍需核实的细节”，不把新文件名当作实现已可靠的证明。`}
      ],quiz:{question:'删失在目标时间之前的记录，原 pROC 段把它设成什么？',options:['Result=0，这正是需要审查的问题','Result=NA，并已自动使用 IPCW','Result=1'],answer:0,explanation:'原 survival$Result=0 无条件作用于所有删失记录。'}},
    {id:'calibration',group:'evaluation',title:'校准：概率是否可信',subtitle:'rms::calibrate、bootstrap 与验证集重新拟合的边界',minutes:16,tags:['calibrate','KM','bootstrap'],range:[818,895],module:'pang-survml-calibration',gallery:{family:'校准'},
      goals:['区分排序与概率一致性','读懂对角线和误差条','识别当前概率评估的局限'],
      sections:[
        {title:'校准回答的是另一件事',body:`模型可以把人排得较好，却系统性高估或低估事件概率。校准图比较预测与观察概率，原图横轴是 predicted OS，纵轴是 observed OS；先确认它使用生存概率还是事件概率。

对角线表示预测与观察相等。不要把 AUC 高当成校准良好。`},
        {title:'原始绘图函数如何工作',body:`plot_calibration_gg 为每个分数列、每个时间点重新用 cph 拟合。时间为 12、36、60 月，cmethod="KM"、method="boot"、B=1000、m=nrow(data)/3。

它取 mean.predicted、KM.corrected 与 std.err，画近似 95% 误差条并裁到 [0,1]。m 约为样本量三分之一意味着分组较粗。`},
        {title:'测试集上的重拟合不是固定预测校准',body:`相同函数分别接收 trainplot_data 和 testplot_data，测试集也重新学习了分数到概率的 Cox 映射。于是所谓 Test 校准图同时涉及测试集拟合和 bootstrap。

正确验证已固定预测时，概率映射应来自开发集，验证集只用于对照预测与观察。`},
        {title:'现有模块要求概率列',body:`calibration_groups.R 读取 Model__risk__12 一类事件风险列，分组计算 1-KM。它仅提供分组曲线，未实现文档目标中的 slope / intercept、Brier 或完整概率生成接口。

本网站保存 18 张原始校准图，其中有历史 Lasso_Cox，保留版本提示而不混合解释。`}
      ],quiz:{question:'校准图与 AUC 的关系是什么？',options:['分别评价概率一致性与区分能力','AUC 高就保证校准良好','只要点落在对角线就证明模型无偏'],answer:0,explanation:'排序和绝对概率准确性是两个不同维度；还需考虑样本量和不确定性。'}},
    {id:'dca',group:'evaluation',title:'DCA 与净获益',subtitle:'阈值概率、Treat All / None 和真实的时间风险输入',minutes:14,tags:['dcurves','net benefit','threshold'],range:[898,986],module:'pang-survml-dca',gallery:{family:'DCA'},
      goals:['读懂阈值轴和基准策略','跟踪 1-S(t) 的来源','区分研究图与临床适用结论'],
      sections:[
        {title:'DCA 比较给定阈值下的策略',body:`DCA 横轴是阈值概率，纵轴是 net benefit；图中含 Treat All、Treat None 和各模型。模型是否有收益，要在有意义的阈值范围内与基准策略比较。

这里解释的是项目图的结构，没有替项目设定临床阈值，也没有从一张图宣布某模型可以直接应用。`},
        {title:'输入必须是目标时间的事件风险',body:`原代码对每个 Cox 适配器用 survfit 取 S(t)，再用 1-S(t) 得到 12、36、60 月事件风险，传给 dcurves::dca。

这一变换不能由 RSF mortality、SVM 分数或 GBM link 的简单归一化替代。它依赖基线、映射来源与时间单位。`},
        {title:'对象覆盖继续影响 DCA',body:`运行到 DCA 时，部分名称已经在测试 AUC 段被覆盖，所以概率来源需要逐个追踪。Test 文件也不能仅因命名就认定输入全是固定训练概率。

新 run_dca.R 要求显式 Model__risk__t 列，没有这些列时会跳过对应时间。没有输出可能是接口缺失，不能解释为模型没有净获益。`},
        {title:'如何阅读现有六张图',body:`先选训练 / 测试集，再选 12 / 36 / 60 月。看曲线在哪些阈值高于两个基准，检查末端样本支持与估计稳定性。图谱保留原始 PDF，并把其结论边界放在旁边。`}
      ],quiz:{question:'run_dca.R 没找到 __risk__36 列时，该如何理解？',options:['该时间缺少接口输入，代码会跳过','模型净获益必然为零','可直接用任意分数补上'],answer:0,explanation:'缺失时间概率是数据/接口问题，不是模型效果结论。'}},
    {id:'km',group:'evaluation',title:'KM 风险分层',subtitle:'中位数切点、log-rank、置信区间与在险人数',minutes:16,tags:['survfit','ggsurvplot','cutoff'],range:[1193,1283],module:'pang-survml-km',gallery:{family:'KM'},
      goals:['读懂生存曲线和风险表','发现两集分别取中位数','区分显著分层与准确概率'],
      sections:[
        {title:'原始高低风险定义',body:`原程序对每个模型取 predictor，大于 median(predictor) 为 high，否则为 low。训练与测试循环分别计算自己的中位数。

这会让两集的 high / low 使用不同阈值。修正文档要求从开发集定切点，再原样用于验证。`},
        {title:'图上每部分表达什么',body:`生存曲线由 survfit(Surv(Time,Event)~RiskGroup) 估计。阴影是置信区间；risk.table 给出各时间仍在风险集中的人数；pval / pval.method 显示 log-rank 检验；中位生存辅助线只在估计达到相应水平时有意义。

风险表后期人数少，曲线即使分开也可能不稳定。`},
        {title:'小 P 值不能替代全部模型评价',body:`显著的组间生存差异说明在这个切点下的分层差别，不能单独证明绝对概率准确、个体预测可靠或外部适用。模型方向未知时，“high”更需要核对含义。

原图包括历史 Lasso_Cox，但当前脚本循环使用 Coxph。图谱保留 16 张 KM 原图并明确各自标签。测试 SVM 图标注 p=0.053，high 曲线在大部分随访期反而较高，直观提醒我们：高分组不能未经核对就称为高死亡风险组。其他图标的是 p<0.0001，是阈值报告而非精确 P 值。`},
        {title:'新脚本锁定开发切点',body:`km_by_locked_cutoff.R 先写 development_cutoffs.csv，再对开发与验证均应用同一个 cut。它解决切点漂移，但仍依赖分数方向、记录对应关系和有效的生存结局。`}
      ],quiz:{question:'验证集高低风险分组的切点应该来自哪里？',options:['开发集预先确定并锁定的切点','验证集重新计算的中位数','看验证集图后调整到显著'],answer:0,explanation:'验证集应评估已经确定的规则。'}},
    {id:'shap',group:'evaluation',title:'SHAP：包装器与全局解释',subtitle:'fastshap 的 nsim=100、原生 XGBoost 和重要性图',minutes:18,tags:['fastshap','shapviz','pred_wrapper'],range:[406,583],module:'pang-survml-shap',gallery:{family:'SHAP',subtype:'蜂群图'},
      goals:['理解解释目标由包装器决定','逐一比较八个包装器','正确读取蜂群图与重要性图'],
      sections:[
        {title:'解释的是模型输出',body:`fastshap::explain 用背景特征表 X 与 pred_wrapper 反复计算预测，本项目 nsim=100。SHAP 贡献对应包装器返回的标量输出。

RSF 取 predicted，GBM 取 link，CoxPH 取 risk，CoxBoost 取 lp，SVM 取 predicted，SuperPC 取 v.pred，PLS-R Cox 取 risk。XGBoost 直接交给 shapviz 做原生解释。`},
        {title:'不同目标的贡献不能直接比较单位',body:`SHAP 正值通常表示相对背景增加目标输出，负值表示减少；但目标可能是 LP、mortality 或其他分数。只有方向确认以后，才可继续解释为更高风险。

本项目多个包装器与不同版本模型并存，所以“哪个模型 SHAP 数值更大”没有统一的概率单位。`},
        {title:'条形图与蜂群图分别看什么',body:`条形图按平均绝对 SHAP 贡献排列变量，展示影响大小，丢失正负。蜂群图同时看贡献分布、正负与特征颜色；每个点对应一个样本。

本项目特征多为二元 / 多类别数字，颜色表达的是编码值，不应自动解释成连续剂量关系。历史图中 15 / 16 个特征也不能拿来解释当前八特征对象。`},
        {title:'近似精度与现有模块的限制',body:`nsim=100 是蒙特卡洛近似次数，不是训练样本数。原始 explain 没有指定 adjust=TRUE，不能默认每行都严格满足加和恒等式，也不能宣称近似误差已经验证。

当前 explain_score.R 有八种标量分支但缺 SuperPC。它把含 $model 的 list 当作载荷，会误拆原生 coxph 的数据框 $model，需先修正载荷识别。网站展示原始代码与这个检查点，不会假装接口已全部运行成功。`}
      ],quiz:{question:'SHAP 条形重要性很高，能否据此判断变量增加风险？',options:['不能，平均绝对贡献不保留方向','能，高就代表增加风险','仅 XGBoost 不能'],answer:0,explanation:'判断方向需要贡献正负、特征值与解释目标的含义。'}},
    {id:'shap-local',group:'evaluation',title:'SHAP：个体与依赖图',subtitle:'力图、瀑布图与不应混淆的 SHAP dependence / PDP',minutes:15,tags:['sv_force','sv_waterfall','dependence'],range:[585,652],module:'pang-survml-shap',gallery:{family:'SHAP',model:'Survivalsvm'},
      goals:['追踪 row_id 对应的记录','理解基线到预测的贡献','纠正原图命名中的混淆'],
      sections:[
        {title:'力图和瀑布图是局部解释',body:`原程序对 SVM 用 row_id=12 画力图，row_id=2 画瀑布图。它们解释的是训练表指定行，不是“典型患者”或经过选择的验证病例。

局部图展示基线输出与各项贡献的关系，读图前要知道当前表、行号、特征值和预测目标。不同 row_id 的图不能当成同一人的两种视图。`},
        {title:'这张 Partial Dependence 文件实际画了什么',body:`代码把 shap_Survivalsvm 与原始八列特征 cbind，横轴取某特征，纵轴取该特征的 SHAP 值，然后加散点与 loess 平滑。

这属于 **SHAP 依赖图**。虽然文件名写 Partial_Dependence_plot，它并不是通过人为改变某特征后平均模型预测得到的传统 PDP。`},
        {title:'少数编码点上的平滑要谨慎',body:`Age、Surgery、Tumor_size 等仅有两个编码值，其他特征也是少数类别。loess 连线不能把这些编码点变成可信的连续响应曲线。

用原图学习时先看离散取值与点云，保留“模型解释”而非因果效应的表述。项目没有提供因果识别或干预估计。`},
        {title:'完整产物与缺失产物',body:`原始目录有 23 张 SHAP PDF。当前脚本只有 SVM 的后续绘图段，其他模型虽然有计算包装器，但相关历史图不一定由这份当前段落生成。

SHAP RData 仅保存部分 explain / shapviz 对象。网站不补造缺少的贡献矩阵或未保存的个体结果。`}
      ],quiz:{question:'横轴特征值、纵轴该特征的 SHAP 值，这是什么图？',options:['SHAP 依赖图','一定是传统 PDP','个体生存概率校准图'],answer:0,explanation:'原代码直接画特征与 SHAP 的散点，和 PDP 的计算过程不同。'}},
    {id:'individual',group:'practice',title:'保存的个体预测应用',subtitle:'只在 RData 中存在的 PLS-R Cox Shiny 页面',minutes:14,tags:['Shiny','RData','baseline'],module:'pang-survml-individual-predictor',widget:'saved-app',
      goals:['找到没有出现在主脚本的 ui/server','跟踪概率变换','分辨教学浏览与实际模型执行'],
      sections:[
        {title:'项目保存了一个额外应用',body:`SHAP 工作空间有 ui 与 server，标题为 PLS-R Cox Survival Prediction。输入为当前八个变量，按钮触发预测，输出 1 到 5 年的生存表与曲线。

这个页面不在当前 1,283 行脚本里。网站展示从保存对象只读提取的 server 代码及输入结构，不调用模型来生成新患者预测。`},
        {title:'server 的概率计算链',body:`输入转成数字 → 按 plsRcox_vars 排列 → predict(plsRcox,type="risk") → 从 plsRcox_base 提取基线 → approx 在 12,24,36,48,60 月插值 → base_surv^risk。

这个结构依赖“risk 的定义与基线是否匹配”。保存的名字和最终曲线并不能证明数学变换、中心化与基线来源已被验证。`},
        {title:'输入标签本身也有差异',body:`原始 factor 映射的 Marital=0 表示 Married，=1 表示 Others；保存应用的标签却出现 No / Yes。复现输入时应回到数据字典，而不是直接相信页面文字。

现有 build_app.R 只生成基础 Shiny 源码，要求 baseline_survival；训练载荷未自动包含这项。两部分需要接通并验证后才有完整应用。`},
        {title:'把保存对象作为学习证据',body:`网站的对象浏览器显示两个 RData 中所有加载名称（含 .Random.seed），以及类、维度和对象大小。缺失 R 包不会阻止简单名称审计，但会限制调用与重新预测，不能用只读加载成功代替功能验证。`}
      ],quiz:{question:'保存的 app 使用 base_surv^risk，这能自动证明概率有效吗？',options:['不能，需要验证 risk 定义、基线来源和尺度匹配','能，只要在 0 到 1 内即可','能，Shiny 能显示就是验证'],answer:0,explanation:'数值范围与页面成功渲染都不足以验证模型的概率变换。'}},
    {id:'reproduce',group:'practice',title:'复现工作流与模块',subtitle:'36 个模块的实际能力、执行顺序与现有验证产物',minutes:18,tags:['Rscript','preflight','模块'],module:'pang-survml',widget:'modules',
      goals:['找到每个模块及完整脚本','识别已验证范围','建立一次可追踪的复现'],
      sections:[
        {title:'先审计输入再训练',body:`项目有 dependency-free preflight、数据准备、Cox 筛选、LASSO、九类模型训练、预测表验证、各类评估与报告清单模块。材料索引可以查看所有 SKILL.md、参考文档和完整 R 源码。

建议执行顺序为：包检查 → 输入审计 → 零时间策略与划分记录 → 开发集预处理 / 选择 / 调参 → 固定预测 → 评估 → SHAP → 输出清单。`},
        {title:'示例命令来自现有脚本参数',body:'```sh\nRscript "蒸馏后的/machine_learning/pang-survml/scripts/preflight.R" data.csv audit\nRscript "蒸馏后的/machine_learning/pang-survml-data/scripts/prepare_split.R" data.csv split 123 0.7 error\nRscript "蒸馏后的/machine_learning/pang-survml-coxph/scripts/train_coxph.R" split/development.csv split/validation.csv coxph\n```\n\n原始数据存在零时间，因此第二条使用 error 策略会按设计停止。需要根据分析依据显式选择处理方案，不能把停止当成程序坏了，也不能默认偷偷替换时间。命令中的相对路径应从原项目根目录运行。'},
        {title:'规范目标与现有实现分开看',body:`| 规范目标 | 目前实际实现 / 边界 |
|---|---|
| 全部算法统一预处理与调参 | 部分脚本仍固定参数，无统一配方 |
| PLS-R 最佳成分数 | 读取 nt.opt，缺失时回退 3 |
| 固定时间 ROC | 有 timeROC 脚本，返回列索引仍需核对 |
| 完整概率校准 | 只有分组 KM 图，无 slope/intercept/Brier |
| 全模型 SHAP | 缺 SuperPC 分支，载荷识别需修正 |
| 完整个体预测 | 生成 app，但 baseline_survival 需补齐 |

现有 _validation 有输入、划分、Cox 与预测表文件；没有全模型重新训练和全部图形验证的证据。`},
        {title:'合成示例只是输出样式演示',body:`example/ 的八张 PNG 由 generate_examples.R 生成，README 明确说明所有数值是合成演示。网站在材料库标为“合成示例”，没有把它们放进原始结果图谱或作为临床实验结果。`}
      ],quiz:{question:'有完整 SKILL.md 和训练脚本，能否写“全部模型已验证”？',options:['不能，需对应运行证据与检查结果','可以，文档就是验证报告','只要文件有 R 扩展名即可'],answer:0,explanation:'文档要求、代码实现、运行产物和验证结果必须分别说明。'}},
    {id:'audit',group:'practice',title:'结果一致性与审计',subtitle:'一次看清版本、字段、时间、对象与图例的十二个问题',minutes:20,tags:['证据','一致性','审计'],module:'pang-survml-artifact-audit',widget:'audit',
      goals:['列出不能混合的产物版本','识别影响评估的关键代码','把不确定结论保留下来'],
      sections:[
        {title:'版本层面的四项检查',body:`1. 八模型当前段与九模型标签历史 PDF。
2. 旧 RData 的 16 特征 / 15 项 rid 与 SHAP RData 的 8 特征。
3. 原始预测 CSV 与历史 ROC PDF 的 AUC 无法按同次输出对齐。
4. _validation 的新划分与原始测试预测表行顺序不同。

文件所在目录相同不等于数据、模型、特征和运行版本相同。`},
        {title:'方法层面的八项检查',body:`1. 列线图 1/3/5 与月单位不一致。
2. 零时间只在局部表修改，后续输入未统一。
3. LASSO 计算 rid，后续默认仍用 sigvar。
4. GBM 与 PLS-R 做了 CV，但原代码最终参数仍固定。
5. XGBoost 把训练集用于早停监控。
6. 算法对象被分数 Cox 适配器覆盖，部分适配器又在测试集拟合。
7. 二元 ROC 把早期删失当对照；测试校准学习了测试结局。
8. KM 两集分别取中位数；SHAP 目标 / 依赖图命名需要说明。

这些问题来自项目代码与材料检查，不是对作者动机的判断。`},
        {title:'图表本身也需要核对',body:`有些 Train ROC 文件内部标题为 Testset；测试 12 月 ROC 中曲线与图例色样存在错位，另有灰色未识别曲线。无法由图例唯一辨认曲线时，只报告 PDF 标注，不替未知曲线补名字。

18 份校准图的曲线几何不完全相同；相似图形不能直接宣称文件复制。相同到三位小数的 AUC 也不足以证明重复模型。`},
        {title:'本网站的证据边界',body:`保留所有原始 PDF 与代码；对每个材料提供项目相对路径、文件大小和 SHA-256。RData 提供只读对象索引。

研究型修正可以作为学习检查点，但没有执行过的训练、未保存的指标和缺失的实验不能补写成真实结果。`}
      ],quiz:{question:'看到三个模型的 AUC 都是 0.828，能否认定它们是重复曲线？',options:['不能，三位小数相同不足以证明','能，AUC 相同就代表每个预测都相同','可以删除其中两条'],answer:0,explanation:'AUC 是汇总量，舍入后相同不等于预测或曲线相同。'}},
    {id:'delivery',group:'practice',title:'从材料到研究报告',subtitle:'把一次分析写成可检查、可复现、可解释的记录',minutes:12,tags:['manifest','报告','自查'],module:'pang-survml-report',
      goals:['建立输出清单','分开报告区分度与校准','给每个结论附可追踪来源'],
      sections:[
        {title:'每一次运行应留下什么',body:`输入数据版本、随访单位与事件定义、缺失 / 零时间策略、开发 / 验证索引、预处理、变量集合、调参过程、模型对象、预测表、评估表、图表、运行环境和检查结果。

现有 build_manifest.R 输出相对路径、扩展名、大小、修改时间、MD5 与角色标签。这是文件清单，并不自动证明临床模型已通过验证。`},
        {title:'不同结果不要互相替代',body:`| 结果 | 核心问题 |
|---|---|
| AUC / C-index | 风险排序能否区分结局 |
| 校准 | 固定时间概率与观察结局是否一致 |
| DCA | 在相应阈值范围中是否有净获益 |
| KM 分层 | 已固定的规则能否划出不同生存组 |
| SHAP | 模型输出如何受特征影响 |

没有一张图能替代所有评估。每类结果还要记录验证类型和不确定性。`},
        {title:'对当前材料可以怎样写结论',body:`可以写：项目展示了八种当前生存建模流程和九类历史模型标签，保留了训练 / 测试图、预测表与解释材料。

需要补充：部分原始评估依赖测试集重新拟合、早期删失二元化和独立切点；不同保存版本之间不能按同次结果合并。不能据此直接给出经过完整验证的“最佳临床模型”。`},
        {title:'完成自学后的检查题',body:`能否从某一张 PDF 回到对应代码段？能否说清它用什么数据、什么特征和什么分数？能否识别概率映射在哪个数据集拟合？能否找到保存模型和复现参数？

如果这些问题都能回答，就不只是“会运行代码”，而是已经掌握如何审查一次生存机器学习分析。`}
      ],quiz:{question:'文件清单能证明模型已经通过完整验证吗？',options:['不能，它只提供产物与来源的索引','能，有 MD5 就说明结果可信','能，PDF 越多越可靠'],answer:0,explanation:'可追踪性是验证的基础，但不能替代方法检查和运行证据。'}}
  ],
  dictionary: [
    ['Age','年龄分组','0: <65；1: ≥65'],['Race','种族','1: White；2: Black；3: Other'],['Gender','性别','0: Female；1: Male'],['Grade','分级','1–4: GreadI–GreadIV（原拼写）'],
    ['Surgery','手术','0: No；1: Yes'],['Radiotherapy','放疗','0: No/Unknown；1: Yes'],['Chemotherapy','化疗','0: No/Unknown；1: Yes'],['Marital','婚姻','0: Married；1: Others'],
    ['AJCC_stage','AJCC 分期','1–4: I–IV'],['T_stage','T 分期','1–4: T1–T4'],['N_stage','N 分期','0: N0；1: N1'],['M_stage','M 分期','0: M0；1: M1'],
    ['SEER_stage','SEER 分期','1: Localized；2: Regional；3: Distant'],['Fibrosis_score','纤维化分组','0: No；1: Yes'],['Tumor_size','肿瘤大小','0: <50mm；1: ≥50mm'],['Income','收入分组','1: $<3500；2: $3500–4999；3: $>5000']
  ]
};
