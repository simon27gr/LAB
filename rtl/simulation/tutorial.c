#include "function.h"

int fact(int n);

int main(int argc, char* argv[]){
    int variable_a,variable_b;
    int final;
    variable_a=75;
    variable_b=fact(9);;
        
    for(int i=0;i<4;i++){
        if(variable_a<variable_b){
            variable_b=variable_b-10;
        }else{
            variable_a=variable_a-10;
        }
    }

    final=max(variable_a,variable_b);

    return final;
}