from typing import List 
import sys 

def push(variables: List[str], registers: List[str]): 
	print("Push")
	for variable, register in zip(variables, registers): 
		print("addi $sp, $sp, -4  # increase stack size")
		print(f"sw {register}, 0($sp)     # push `{variable}` onto stack")
	print()
        
def pop(variables: List[str], registers: List[str]): 
	print("Pop")
	for variable, register in zip(variables, registers): 
		print(f"lw {register}, 0($sp)     # pop `{variable}` from stack")
		print("addi $sp, $sp, 4   # decrement stack size ")
        
if __name__ == "__main__": 
	if len(sys.argv) != 4: 
		print("usage: python3 stack.py [variables] [registers]")
	variables = sys.argv[1].split(",")
	registers = sys.argv[2].split(",")
	push(variables, registers) 
	pop(list(reversed(variables)), list(reversed(registers)))
	
