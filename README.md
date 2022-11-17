# Computer_Arc
self-core
完成了取指模块设计，主要针对存在16bits压缩指令情况下，如何每次顺利取出一条指令，每次取指可能会遗留16bits指令，需要和下次取得的指令进行拼接。该IF模块在连续取指时可以做到每周期取出一条指令，16bits/32bits。遇到跳转指令时，要重新给PC赋值取指。跳转时只有一种情况需要连续两次取指得到一条完整指令：不对齐32bits指令。
测试简单找了个C代码编译的可执行文件，其中对于各种情况的指令取指：对齐/不对齐、16/32bits，都有覆盖到，经验证没有问题。
