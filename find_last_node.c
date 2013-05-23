#include "stu.h"

NODE * find_last_node(NODE *hd){

if(hd->next==NULL){

return  hd;

}
return  find_last_node(hd->next);

}
