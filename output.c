#include "stu.h"

void output(NODE *hd){
	int i;
	i=1;
	printf("输出所有学生的信息...\n");
while(hd->next!=NULL){
	printf("\n");
printf("第%d为学生的信息################\n",i);
printf("学号：%d\n姓名：%s\n年龄:%d\n生日:%s\n地址:%s\n电话号码:%s\n邮箱:%s\n",hd->next.id,hd->next.name,hd->next.age,hd->next.birth,hd->next.address,hd->next.phone,hd->next.mail);
i++;
hd->next=hd->next->next;
}

}
