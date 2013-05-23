#include "stu.h"

NODE *add_node(){
NODE *tmp;
if((tmp=malloc(sizeof(NODE)))!=NULL){
tmp->next=NULL;
}


return tmp;

}


NODE *  add_data(){
NODE *tp;
tp=add_node();
printf("请输入该学生的学号:");
scanf("%d",&tp->stu.id);
printf("请输入该学生的姓名:");
scanf("%s",tp->stu.name);
printf("请输入学生的年龄:");
scanf("%d",&tp->stu.age);
printf("请输入学生的生日");
scanf("%s",tp->stu.birth);
printf("请输入学生的地址:");
scanf("%s",tp->stu.address);
printf("请输入学生的电话号码:");
scanf("%s",tp->stu.phone);
printf("请输入学生的邮箱:");
scanf("%s",tp->stu.mail);
printf("输入完成..\n");
return tp;
}
