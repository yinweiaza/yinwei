#include "stu.h"


int main(){
int n;
NODE *head,*tmp;
head=add_node();    //链表头
while(1){          //循环，使可以多次进行选择
	menu();
	scanf("%d",&n);
	switch(n){
		case 1:
			input(head);
			break;
		case 2:
			output(head);
			break;
		case 3:
			tmp=search(head);
			show(tmp);
			break;
		case 4:
			order(head);
			break;
		default:
			perror("输入的格式不对\n");
	
	}



}


return 0;
}



void  show(NODE *tp){
	if(tp!=NULL){
		printf("学号:%d\n姓名:%s\n年龄:%d\n生日:%s\n地址:%s\n电话号码:%s\n邮箱:%s\n",tp->next.id,tp->next.name,tp->next.age,tp->next.birth,tp->next.address,tp->next.phone,tp->next.mail);
	}
}
