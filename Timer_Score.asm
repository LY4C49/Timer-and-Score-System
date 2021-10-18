ORG 0000H
AJMP MAIN				;主程序入口
ORG 0003H
AJMP JINT0          	   ;外部中断0入口								
ORG 000BH
AJMP TIME0             ;定时器0中断入口
ORG 0030H

MAIN: 	                
	 	MOV SP,#60H  ;设堆栈
  		MOV P0,#00H  ;对P0口进行初始化
       ;开中断
	  	SETB EA           
	  	SETB ET0            
	  	SETB EX0          
	  	CLR IT0
        ;----------	
;计时器的初始化设置，使用模式16位定时       
	  	MOV TMOD,#01H        ;定时模式1
	  	MOV R1,#0		       ;通过R1来记录定时器中断个数
        ;----------
        ;对数码管相关接口的初始化	  	
	  	SCK BIT P0.4
	  	RCK BIT P0.5
	  	RST BIT P0.6
	  	DAT BIT P0.7
	  	SMG1 BIT P0.3
	  	SMG2 BIT P0.2
	  	SMG3 BIT P0.1
	  	SMG4 BIT P0.0    
        ；-----------
        ；关闭蜂鸣器
	  	BEEP BIT P1.3
        ；----------
       ；对存放数据的工作寄存器进行初始化赋值           
       ；R2存放计时器十位
       ；R3存放计时器个位
       ；R4存放A队比分
       ；R5存放B队比分
	   	MOV R2,#0      	 
      	MOV R3,#0       
	 	MOV R4,#0
	  	MOV R5,#0	   	
	    
 	    ；---------------
     ；初始化设置结束
     ；---------------

；上电后，数码管不显示，通过按键激活。省电并减小数码管损耗
MAD0:	LCALL KEY			    ;调用键盘扫描子程序
	   	CJNE A,#0F0H,SHOW0 	;判断是否有键按下
	   	AJMP MAD0       	    ;无键按下，循环
	
        ；激活后，数码管显示，等待设置计数和比分初值
SHOW0: LCALL SMGSHOW
        LCALL KEY
	CJNE A,#0,NEXT     ;只要不是按下0键（开始计时），就执行相应
                            ;按键功能
                         ;进行初始化设置,此时只有加减时，加减分按键有效
		 AJMP MBJS      ;按下0键，开始计时
       
;----------------
      ;通过A的值确定按下的是哪一个按键，并执行相应操作
NEXT:
		CJNE A,#1,NEXT1
		CJNE R2,#9,INCREASER2
		MOV R2,#0
		AJMP DIS
INCREASER2:
        INC R2
		AJMP DIS		
NEXT1:  CJNE A,#2,DIS
        CJNE R3,#9,INCREASER3
		MOV R3,#0
		AJMP DIS
INCREASER3:
        INC R3        
        ;SETB 01H
DIS:    LCALL SMGSHOW
       AJMP SHOW0 
		;---------------


MBJS: 	
      	LCALL MBJSQ        ;调用计时器子程序
      	      	      	 	
SHOW:  LCALL SMGSHOW  
        LCALL KEY
        CJNE A,#0F0H,MBJS
	      AJMP SHOW

;计时器子程序
;-------------------
MBJSQ:	SETB BEEP
	  	CLR 00H      		
    ;开始执行计时程序前判断不为00秒
ST0:  	CJNE R2,#0,START
        CJNE R3,#0,START
        ;---------------

        ;到达00秒，执行到时间报警的程序
    	CLR 00H	      		
	   	CLR TR0
     	MOV R2,#0       
	   	MOV R3,#0
SHOW1: LCALL SMGSHOW  	 ;数码管显示时间00，蜂鸣器响
        CLR BEEP
	   	LCALL KEY
	   	CJNE A,#0F0H,CLOSE
		AJMP SHOW1
CLOSE:	SETB BEEP	    ;不断扫描键盘直至有键按下,关闭蜂鸣器
	   	AJMP SHOW0
;报警分支结束
;------------
;再按一次0键开始计时，即开始计时必须按两次开始
;防止误触，同时模拟比赛开始时有预备命令和正式开始命令
START:	LCALL SMGSHOW   
	   	LCALL KEY;扫描键盘，无键按下循环判断是否到时间（上面的代码）
	   	CJNE A,#0F0H,GO	    
	   	AJMP ST0           
GO:  	CJNE A,#0,RES0  	    ; 0键（启动/停止）按下
	   	JBC 00H,STOP0	  	    ;00H为0时为启动，为1时为停止
        ;为计时器赋初值
	   	MOV TH0,#0D8H    			                 
	   	MOV TL0,#0F0H
        ;开始计时，蜂鸣器响一声
		CLR BEEP
        MOV R0,#5
BEE:	LCALL DELAY
        DJNZ R0,BEE
        SETB BEEP
        ;-----------
        ;开始计时
	   	SETB TR0        	;启动定时器，       
	   	SETB 00H  	    
	   	AJMP ST0
RES0: 	JB 00H,ST0     		;停止计时时才能复位
     	CJNE A,#1,ST0	    
	   	AJMP MBJSQ      	;按下复位键回到子程序开始 
         ;----------
         ;暂停程序的部分，保证暂停后可以对计时时间和比分进行修改
         ;按两次0键恢复计时，开始时蜂鸣器会响一声
STOP0:	CLR TR0         	;为暂停功能时，停止定时器，停止计时
        LCALL SMGSHOW
        LCALL KEY
;以下为判断按下的是哪个按键并执行相应操作
;必须注意的是：按第一下0键之后，不可再对数据进行修改 
		CJNE A,#0,LATER1
	   	AJMP ST0
LATER1: CJNE A,#1,LATER2
        CJNE R2,#9,AAR2
		MOV R2,#0
		AJMP STOP0
AAR2:   INC R2
        LCALL SMGSHOW
        AJMP STOP0

LATER2: CJNE A,#2,LATER3
        CJNE R3,#9,AAR3
		MOV R3,#0
		AJMP STOP0
AAR3:    INC R3
        LCALL SMGSHOW
        AJMP STOP0

LATER3: CJNE A,#4,LATER4
        CJNE R4,#15,AAR4
		AJMP STOP0
AAR4:    INC R4
        LCALL SMGSHOW
        AJMP STOP0

LATER4: CJNE A,#5,LATER5
        CJNE R4,#0,DDR4
		AJMP STOP0
DDR4:   DEC R4
        LCALL SMGSHOW
        AJMP STOP0

LATER5: CJNE A,#6,LATER6
        CJNE R5,#15,AAR5
		AJMP STOP0
AAR5:    INC R5
        LCALL SMGSHOW
        AJMP STOP0

LATER6: CJNE A,#7,LATER7
        CJNE R5,#0,DDR5
		AJMP STOP0
DDR5:   DEC R5
        LCALL SMGSHOW
        AJMP STOP0

LATER7: CJNE A,#12,LATER8
        MOV R4,#0
		LCALL SMGSHOW
		AJMP STOP0

LATER8: CJNE A,#13,LATER9
        MOV R5,#0
		LCALL SMGSHOW
		AJMP STOP0

LATER9: CJNE A,#10,STOP0
        MOV R4,#0
		MOV R5,#0
		LCALL SMGSHOW
		AJMP STOP0
     ;暂停分支结束
	   	;------------

;计分器子程序
;------------                                   
AJSQ: CJNE R4,#15,A1			  ;A队得分不为F分，则加一分
      AJMP 	W1
A1:   INC R4
W1:   LCALL SMGSHOW
      RET

A1JSQ:CJNE R4,#0,A11           ;A队得分不为0分，则减一分
      AJMP W11
A11:DEC R4
W11:LCALL SMGSHOW
RET

BJSQ: CJNE R5,#15,B1			  ;B队得分不为F分，则加一分
      AJMP 	W2
B1:   INC R5
W2:   LCALL SMGSHOW
      RET

B1JSQ:CJNE R5,#0,B11           ;B队得分不为0分，则减一分
AJMP W22
B11:DEC R5
W22:LCALL SMGSHOW
RET

CJSQ: MOV R4,#0					  ;计分器复位，两队得分清零
      MOV R5,#0
      LCALL SMGSHOW
      RET
;计分器子程序结束
;---------------------

;外部中断0中断服务子程序 （系统复位使用）
;---------------------------------------
JINT0:	CLR TR0
    	MOV DPTR,#MAIN
	  	POP ACC		   		;弹出原返回地址	
	  	POP ACC
	  	PUSH DPH				;将主程序入口地址入栈
	  	PUSH DPL
	  	RETI

;定时器0中断服务子程序
;------------------------
TIME0:	INC R1           		; R1记录定时器溢出中断次数 
	  	MOV TH0,#0D8H			;重装定时器预置初值
	 	MOV TL0,#0F0H
        ;键盘扫描，若有键按下执行相应功能。否则直接跳到结尾
AJS:  	LCALL KEY
        CJNE A,#0F0H,DOIT
		AJMP QL
DOIT:
        CJNE A,#4,A1JS     ;4键按下，A队加一分子程序
      	LCALL AJSQ
		AJMP QL  

A1JS:	CJNE A,#5,BJS         ;5键按下，A队减一分子程序
        LCALL A1JSQ
		AJMP QL

BJS:    CJNE A,#6,B1JS     ;6键按下，B队加一分子程序
      	LCALL BJSQ
		AJMP QL

B1JS:   CJNE A,#7,CJS      ;7键按下，B队减一分子程序
       LCALL B1JSQ
	   AJMP QL
 		   
CJS:    CJNE A,#10,DJS     ;10键按下，调用计分器复位子程序
      	LCALL CJSQ
		AJMP QL

DJS:    CJNE A,#12,EJS     ;12键按下，A队比分清零
        MOV R4,#0
		AJMP QL

EJS:     CJNE A,#13,QL     ;13键按下，B队比分清零
        MOV R5,#0
		AJMP QL
		;按键扫描与执行部分结束
QL:	  	CJNE R1,#50,OUT4 		;R1满50清0 
                                ;注意：定时1s,R1应是100清零（12MHz）
                                ;这里根据中断程序和实际计时效果调整为50进行补偿
                                ;使用者需对其结合实际硬件和代码进行修改

     ;对当前剩余秒数值进行修改
	  	MOV R1,#0
	  	CJNE R3,#0,LP
	  	MOV R3,#9
	  	DEC R2
	  	AJMP OUT4
LP:     DEC R3
OUT4:	RETI      	;其他键按下,返回子程序

;数码管显示子程序，通过视觉暂留效应达到同时显示的效果
;---------------------------
SMGSHOW: 
        MOV A,R2      	        ;显示计时时间的十位
	  	SETB SMG4		 	    ;选中数码管1
	  	CALL SMG
	  	MOV R6,#4 
	  	CALL DELAY	     	    ;延时2ms
	  	CLR SMG4		  	    ;关闭数码管1
	  	
	  	MOV A,R3      	        ;显示计时时间的个位
	  	SETB SMG3	   		    ;选中数码管2
    	CALL SMG
      	MOV R6,#4
	  	CALL DELAY	   		    ;延时2ms
	  	CLR SMG3			    ;关闭数码管2
	  	
	  	MOV A,R4      		    ;显示A队得分值
	  	SETB SMG2				;选中数码管3
	  	CALL SMG
	  	MOV R6,#4 
	  	CALL DELAY				;延时2ms
	  	CLR SMG2	    	    ;关闭数码管3
	  	
    	MOV A,R5				;显示B队得分值
	  	SETB SMG1     		    ;选中数码管4
	  	CALL SMG	    		;调用1位数码管显示子程序
	  	MOV R6,#4
	  	CALL DELAY    			;延时2ms
	  	CLR SMG1				;关闭数码管4
	 
	  	RET
	  	
;1位数码管显示子程序（向74HC595发送1个字节）
;--------------------------------------------
SMG:   MOV DPTR,#SMGTAB   ;装入表头
	   MOVC A,@A+DPTR     ;查表取值
	  	
S0:		CLR RST         	;RST清0
	  	CLR RCK         ;RCK清0
	  	MOV R0,#8       	;进行8位数据的传输
S1:   	CLR SCK  	      	;SCK清0
	  	RRC A      		   
	  	JC S2           	    ;当CY=1时将DAT置1,当CY=0时，将DAT清0
	  	CLR DAT
	  	AJMP S3
S2:   	SETB DAT
S3:   	SETB SCK   			
	  	DJNZ R0,S1     	    ;判断8位数据是否传输完毕
	  	SETB RCK        	
	 	RRC A
	  	RET

;键盘扫描子程序
;-----------------
KEY:  	MOV P2,#0F0H	   	;查有键按下
	  	MOV A,#0F0H
	  	CJNE A,P2,K01
	  	AJMP OUT
K01:  	MOV R6,#20
      	ACALL DELAY	     ;延时20ms去抖
	  	MOV P2,#0F0H      ;重查有键按下
	  	CJNE A,P2,K02
	  	AJMP OUT
K02:  	MOV P2,#0FEH	   	;行线1变低
	  	MOV A,P2
	  	CJNE A,#0FEH,YES  	;查何键按下
      	MOV P2,#0FDH	   	;行线2变低
      	MOV A,P2
      	CJNE A,#0FDH,YES  	;查何键按下
	  	MOV P2,#0FBH	   	;行线3变低
	  	MOV A,P2
 	  	CJNE A,#0FBH,YES ;查何键按下
	  	MOV P2,#0F7H	   	;行线4变低 
	  	MOV A,P2
	 	CJNE A,#0F7H,YES		;查何键按下
	  	AJMP K02
YES:  	ACALL KEY_VALUES	;取键值存入A
      	LCALL KEYRE
OUT:  	RET

;查键释放子程序
;-----------------------
KEYRE:	PUSH ACC	       	;保护ACC的值
REL0: 	MOV P2,#0F0H     		;查键释放
      	MOV A,#0F0H
      	CJNE A,P2,REL0
	  	MOV R6,#20	   			;输入延时10ms参数
	  	LCALL DELAY      		;延时10ms去抖
	  	CJNE A,P2,REL0   		;重查键释放
	  	POP ACC
	  	RET

;延时子程序
;-----------------
DELAY:	NOP  
DLY0: 	MOV R7,#250
DLY1:	DJNZ R7,DLY1
	  	DJNZ R6,DLY0
	  	RET

;查键值子程序
;-----------------	  
KEY_VALUES:NOP
	  	CJNE A,#77H,K1
	  	MOV A,#0				;键号0（秒表计时器的启动/停止键）
	  	AJMP OUT1
K1:   	CJNE A,#7BH,K2
	  	MOV A,#1				;键号1（计时器十位）
	 	AJMP OUT1
K2:   	CJNE A,#7DH,K3
	  	MOV A,#2				;键号2（计时器个位）
	  	AJMP OUT1
K3:   	CJNE A,#7EH,K4
	  	MOV A,#3				;键号3	
	  	AJMP OUT1
K4:   	CJNE A,#0B7H,K5
	  	MOV A,#4				;键号4（A队得一分）
	  	AJMP OUT1
K5:   	CJNE A,#0BBH,K6
	  	MOV A,#5				;键号5（A队减一分）
	 	AJMP OUT1
K6:   	CJNE A,#0BDH,K7
	  	MOV A,#6H				;键号6（B队得一分）
	  	AJMP OUT1
K7:   	CJNE A,#0BEH,K8
	  	MOV A,#7				;键号7（B队减一分）
	  	AJMP OUT1
K8:   	CJNE A,#0D7H,K9
	  	MOV A,#8				;键号8
	  	AJMP OUT1
K9:   	CJNE A,#0DBH,K10
	  	MOV A,#9				;键号9
	  	AJMP OUT1
K10:  	CJNE A,#0DDH,K11
	  	MOV A,#10				;键号10（计分器复位清零）
	  	AJMP OUT1
K11:  	CJNE A,#0DEH,K12
	 	MOV A,#11				;键号11
	 	AJMP OUT1
K12:  	CJNE A,#0E7H,K13
	  	MOV A,#12				;键号12（A队比分清零）
	  	AJMP OUT1
K13:  	CJNE A,#0EBH,K14
	  	MOV A,#13				;键号13（B队比分清零）
	  	AJMP OUT1
K14:  	CJNE A,#0EDH,K15
	  	MOV A,#14				;键号14
	  	AJMP OUT1	
K15:  	CJNE A,#0EEH,OUT1
	  	MOV A,#15				;键号15
OUT1: 	RET

;数码管段码表
;-------------------
SMGTAB:	DB 0FCH,60H,0DAH,0F2H	 ;对应数字0、1、2、3
	  	DB 66H,0B6H,0BEH,0E0H	    ;对应数字4、5、6、7
	   	DB 0FEH,0F6H,0EEH,3EH      ;对应数字8、9，字母A、B
	   	DB 9CH,7AH,9EH,8EH	        ;对应字母C、D、E、F

END
