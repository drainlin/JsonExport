# 修改说明

由于项目中不得不使用MJExtension，又不想自己一个字一个字写model，于是发现这款软件挺方便的就魔改了一下

- 新增了与关键字冲突后的自定义后缀
- 修复了copyright的问题，调整了适合国人的日期显示
- 新增了小驼峰法与蛇形法的互转，默认为json的键命名属性
- 修复了一些小问题，汉化了一些词

最后感谢原作者们，不想自己打包编译的可以去release下载编译好的执行文件即可。

## 预览图：

![screeenshort](./screeenshort.png)



以下是原README

------



# PZJsonExport


## 这是什么

PZJsonExport 是由自动生成 MJExtension 模型的 mac app，告别手写模型属性痛苦。

![example](https://raw.githubusercontent.com/EvoIos/PZJsonExport/master/pzjsonexport.gif)

**注：** 

PZJsonExport 由 JSONExport 魔改出来的，界面和 JSONExport 一样，部分代码也是直接从 JSONExport 贴过来的。

**为什么不用 JSONExport**

1.因为 JSONExport 没有生成 MJExtension 模型的方法。

2.如果使用的话，需要去手动映射。


## 功能

- [x] 自动映射数组中的字典。如, .h 中 `NSArray <AClass *> *bClass`, 在对应的 .m BClass 里，自动提供映射方法 `+ (NSDictionary *)objectClassInArray`.
- [x] 关键字替换，会在关键字属性后面添加 Field 字符串.
- [x] 可以修改类前缀，同 JSONExport.
- [ ] 下划线转驼峰
- [ ] 首字母大写转小写

## 使用

直接复制 json 到 input json 窗口就可以了。

### 感谢

感谢 [JSONExport]( https://github.com/Ahmed-Ali/JSONExport) 

### 协议

MIT