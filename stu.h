#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

//结构体的创建->链表
typedef  struct  student{
int id;
char name[5];
int age;
char birth[10];
char  address[20];
char phone[20];
char mail[20];
}STU;

typedef struct  node{
struct  student  stu;
struct  node  *next;
}NODE;


//函数
extern  NODE *add_node();
extern NODE * add_data();
extern  void menu();
extern  NODE *search(NODE *);  //查询功能->1.学号;2.姓名
