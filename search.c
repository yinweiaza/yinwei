#include "stu.h"
#include <string.h>

NODE * search(NODE *hd){
int tp;
tp=choose();
switch(tp){
	case 0:
		return NULL;
	case 1:
		return 	id_search(hd);
	case 2:
		return  name_search(hd);
	default:
		printf("输入错误\n");
		exit(EXIT_FAILURE);


}


}


int choose(){
	int  cn;
printf("选择查询方法（学号/姓名）:\n");
printf("1.学号\n");
printf("2.姓名\n");
printf("请输入(1/2):");
scanf("%d",&cn);
switch(cn){
	case 1:
		return 1;
	case 2:
		return 2;
	default:
		perror("输入错误\n");
}
return 0;

}


NODE *id_search(NODE *hd){
int the_id;
printf("请输入要查询的学号:");
scanf("%d",&the_id);
while(hd->next!=NULL){
if(hd->next.id==the_id){
return  hd->next;
}
hd->next=hd->next->next;	
}
printf("没有该学号的学生\n");

return NULL;

}


NODE *name_search(NODE *hd){
char nm[5];
printf("请输入要查询的姓名:");
scanf("%s",nm);
while(hd->next!=NULL){
if(strncmp(nm,hd->next.name,5)==0){
printf("找到该学生的信息了\n");
return  hd->next;
}
hd->next=hd->next->next;
}
printf("没有该姓名的学生\n");
return NULL;
}
