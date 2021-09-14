# quartz

## StdSchedulerFactory

- StdSchedulerFactory 实现了 SchedulerFactory 接口，提供一个静态方法 getDefaultScheduler()，这个方法内会实例化一个 StdSchedulerFactory 对象，再调用该对象的 getScheduler() 方法返回一个实现了 Scheduler 接口的对象。getScheduler() 方法中首先检查是否已经读取了配置文件，如果没有就会调用 initialize() 方法去读取配置文件来配置一个名为 cfg 的 PropertiesParser 对象；配置文件通过系统变量 org.quartz.properties 指定，如果没有设置这个系统变量，就使用默认值 quartz.properties，如果在classpath根路径下存在 quartz.properties文件，则使用该文件，否则使用quartz包(org/quartz)中的 quartz.properties文件。配置文件中的属性将和所有系统变量合并后保存到 cfg 对象中，系统变量将覆盖配置文件中的同名配置（即运行时使用 -D指定的参数）。