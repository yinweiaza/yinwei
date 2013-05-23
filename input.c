#include "stu.h"


void input(NODE *hd){
NODE *tmp;
tmp=find_last_node(hd);
tmp->next=add_data;
}
