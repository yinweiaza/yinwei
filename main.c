#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
//结构体
typedef  struct  student{
	char name[20];
	char ID[20];

}STU;
typedef  struct  node{
	STU d_stu;
	struct node  *next;
}NODE;
NODE *head;

//变量声明
int nd_n=0;   //链表节点数

//声明函数
NODE *add_node();  //添加链表节点
int  add_date();  //添加数据
NODE *find_last_node(NODE *);  //查询最后一个节点
void  print_list(NODE *);   //打印所有的数据


//main入口
int main(int argc,char *argv[]){
	char c;
	int status;
head=add_node();	
printf("添加数据吗？(y/n):");
scanf("%c",&c);

switch(c){                            //选择口
	case 'y'|'Y':
		status=add_date();
		if(status==0){
		puts("输入数据成功");
		}
		break;
	case 'n'|'N':
		break;
	default:
		perror("输入错误");
		exit(EXIT_FAILURE);


}

		print_list(head);
		printf("全部打印完全.............\n");
return 0;

}

//创建链表节点
NODE *add_node(){
	NODE *link;
	if((link=malloc(sizeof(NODE)))!=NULL){
	
		bzero(&link->d_stu,sizeof(STU));
	link->next=NULL;
	return  link;
	
	}
return NULL;

}


//添加数据
int  add_date(){
NODE *ld,*last;
char nm[20],id[20];
ld=add_node();
bzero(nm,20);
bzero(id,20);
printf("输入学生姓名:");
scanf("%s",nm);
printf("输入学生学号:");
scanf("%s",id);
strcpy(ld->d_stu.name,nm);
strcpy(ld->d_stu.ID,id);
last=find_last_node(head);
last->next=ld;
nd_n++;
return 0;
}



//找到最后一个链表节点
NODE *find_last_node(NODE *head){
	NODE  *last_node;
	last_node=head;
	if(NULL !=head->next)
	{
	return  find_last_node(head->next);
	}
return  last_node;

}


int pn=0;
//打印所有的数据
void print_list(NODE *head){
	if(head!=NULL&&pn!=0){
printf("姓名：%s\n学号:%s\n",head->d_stu.name,head->d_stu.ID);
nd_n--;
	}
	pn++;
	if(nd_n==0)
		return;
return print_list(head->next);
}
