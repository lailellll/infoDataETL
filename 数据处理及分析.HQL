use db_msg;



create table db_msg.tb_msg_source(
                                     msg_time string comment "消息发送时间",
                                     sender_name string comment "发送人昵称",
                                     sender_account string comment "发送人账号",
                                     sender_sex string comment "发送人性别",
                                     sender_ip string comment "发送人ip地址",
                                     sender_os string comment "发送人操作系统",
                                     sender_phonetype string comment "发送人手机型号",
                                     sender_network string comment "发送人网络类型",
                                     sender_gps string comment "发送人的GPS定位",
                                     receiver_name string comment "接收人昵称",
                                     receiver_ip string comment "接收人IP",
                                     receiver_account string comment "接收人账号",
                                     receiver_os string comment "接收人操作系统",
                                     receiver_phonetype string comment "接收人手机型号",
                                     receiver_network string comment "接收人网络类型",
                                     receiver_gps string comment "接收人的GPS定位",
                                     receiver_sex string comment "接收人性别",
                                     msg_type string comment "消息类型",
                                     distance string comment "双方距离",
                                     message string comment "消息内容"
);

// 导入数据
load data local inpath '/export/chat_data-30W.csv' into table tb_msg_source;

select * from tb_msg_source tablesample(1K); // 随机取1K大小的数据


// 过滤后的数据表
create table db_msg.tb_msg_etl(
                                  msg_time string comment "消息发送时间",
                                  sender_name string comment "发送人昵称",
                                  sender_account string comment "发送人账号",
                                  sender_sex string comment "发送人性别",
                                  sender_ip string comment "发送人ip地址",
                                  sender_os string comment "发送人操作系统",
                                  sender_phonetype string comment "发送人手机型号",
                                  sender_network string comment "发送人网络类型",
                                  sender_gps string comment "发送人的GPS定位",
                                  receiver_name string comment "接收人昵称",
                                  receiver_ip string comment "接收人IP",
                                  receiver_account string comment "接收人账号",
                                  receiver_os string comment "接收人操作系统",
                                  receiver_phonetype string comment "接收人手机型号",
                                  receiver_network string comment "接收人网络类型",
                                  receiver_gps string comment "接收人的GPS定位",
                                  receiver_sex string comment "接收人性别",
                                  msg_type string comment "消息类型",
                                  distance string comment "双方距离",
                                  message string comment "消息内容",
                                  msg_day string comment "消息日",
                                  msg_hour string comment "消息小时",
                                  sender_lng double comment "经度",
                                  sender_lat double comment "纬度"
);

show tables;

// 过滤数据
insert overwrite table tb_msg_etl (
select *,date(msg_time) as msg_day,hour(msg_time) as msg_hour,split(sender_gps,',')[0] as sender_lng,
       split(sender_gps,',')[1] as sender_lat from tb_msg_source where length(tb_msg_source.sender_gps)>0);

select * from tb_msg_etl tablesample (1k);

// 统计今日消息总量
create table if not exists tb_rs_total_msg_cnt comment '每日消息总量' as (
    select msg_day,count(*) as total_msg_cnt from tb_msg_etl group by msg_day
);

select * from tb_rs_total_msg_cnt tablesample ( 1k );

// 统计每小时消息量、发送和接收用户数
create table if not exists tb_rs_hour_msg_cnt comment '每小时消息量趋势' as (
    select msg_hour,count(*) as total_msg_cnt,count(distinct sender_account) as sender_usr_cnt,
           count(distinct receiver_account) as receiver_usr_cnt from tb_msg_etl group by msg_hour
);

select * from tb_rs_hour_msg_cnt tablesample ( 1k );

// 统计今日各地区发送消息数据量
create table if not exists tb_rs_loc_cnt comment '今日各地区发送消息总量' as (
    select sender_lng as longitude,sender_lat as latitude,count(*) as total_msg_cnt
    from tb_msg_etl group by sender_lng, sender_lat
);

select * from tb_rs_loc_cnt tablesample ( 1k );

// 统计今日发送消息和接收消息的用户数
create table if not exists tb_rs_usr_cnt comment '今日发送消息人数、接受消息人数' as (
    select msg_day,count(distinct sender_account) as sender_usr_cnt,count(distinct receiver_account) as receiver_usr_cnt
    from tb_msg_etl group by msg_day
);

select * from tb_rs_usr_cnt tablesample ( 1k );

// 统计发送消息条数最多的Top10用户
create table if not exists tb_rs_s_user_top10 comment '发送消息条数最多的Top10用户' as (
    select sender_name as username,count(*) as sender_msg_cnt from tb_msg_etl group by sender_name order by sender_msg_cnt DESC limit 10
);

select * from tb_rs_s_user_top10 tablesample ( 1k );

// 统计接收消息条数最多的Top10用户
create table if not exists tb_rs_r_user_top10 comment '接收消息条数最多的Top10用户' as (
    select receiver_name as username,count(*) as receiver_msg_cnt from tb_msg_etl group by receiver_name order by receiver_msg_cnt DESC limit 10
);

select * from tb_rs_r_user_top10 tablesample ( 1k );

// 发送人的手机型号分布
create table if not exists tb_rs_sender_phone comment '发送人的手机型号分布' as (
    select sender_phonetype,count(sender_account) as cnt from tb_msg_etl group by sender_phonetype
);

select * from tb_rs_sender_phone tablesample(1k);

// 发送人的os分布
create table if not exists tb_rs_sender_os comment '发送人的OS分布' as (
    select sender_os,count(sender_account) as cnt from tb_msg_etl group by sender_os
);

select * from tb_rs_sender_os tablesample ( 1k );
