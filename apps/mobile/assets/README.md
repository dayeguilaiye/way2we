# 应用素材

植物装饰沿用已采纳原型：暖杏来自 `assets/plates/botanical.png`，青瓷与雾玫来自 `prototype/assets/botanical-*.png`。生成记录见原位置的 JSON／提示词与 `docs/design/visual-reference.md`。

品牌标题与用户自设空间名使用 Noto Serif SC Regular，覆盖字体提供的全部字形；正文与输入控件使用系统字体。原始变量字体来自 [Google Fonts 官方仓库](https://github.com/google/fonts/tree/main/ofl/notoserifsc)，文件 `NotoSerifSC[wght].ttf`，SHA-256 为 `050080d9255a86808f2945bffac582b31ef32bc36411ce29563b4961670c66f9`。通过 `tools/build-brand-font.py` 固定为 400 字重，保留完整字符映射；产物为 `fonts/brand-serif.ttf`。OFL 许可证已随应用打包并注册至 Flutter LicenseRegistry。

字体构建使用 fontTools 4.59.2（MIT，开发工具依赖），版本固定于 `tools/font-requirements.txt`。重新生成时，安装该文件中的依赖，然后执行 `python tools/build-brand-font.py <下载的字体文件>`；脚本检查源文件摘要和生成前后的字形覆盖。全字形文件支持新增文案及用户自设空间名称的统一展示。
