.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern srand: proc
extern rand: proc
extern time: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.data

;variabile ajutatoare pentru procesul din spate:
;unde: 	 0 - spatiu interzis (de calcat)
		;1 - spatiu permis
		;2 - locul unde e broasca
		;3 - refugiu gol
		;4 - refugiu cu broasca
matrice	db	0,3,0,3,0,3,0,3,0,3,0	;randul cu refugii
		db	11 dup(0)				;apa
		db	11 dup(0)				;apa
		db	11 dup(0)				;apa
		db	11 dup(0)				;apa
		db	11 dup(1)				;trotuar
		db	11 dup(1)				;drum
		db	11 dup(1)				;drum
		db	11 dup(1)				;drum
		db	11 dup(1)				;drum
		db	1,1,1,1,1,2,1,1,1,1,1	;trotuar
		
;;;;;;;;;;;;;;;;;;;;;;;;;;; variabile pentru BROASCA:
viata dd 5

frog_coord_x dd 305
frog_coord_y dd 430

frog_index_x dd 5		;pozitia la care se afla initial broasca in matrice
frog_index_y dd 10

check_index_x dd 0		;voi folosi variabilele astea ca sa verific daca broasca poate calca pe urmatoarea celula
check_index_y dd 0

pos_frog dd 0				;deplasamentul fata de inceputul matricii matrice pentu a ajunge la un anumit element

nr_broaste dd 5

little_frog_block 	dd 0	;voi salva aici latimea perimetrului de desenat peste broastele mici
heart_block			dd 0	;voi salva aici latimea perimetrului de desenat peste inimile de viata

;;;;;;;;;;;;;;;;;;;;;;;;;; variabile pentru miscarea MASINILOR:

; pos_lane reprezinta deplasamentul fata de inceputul matricii matrice pana la pozitia din matrice de la care se incepe shiftarea masinilor
; exemplu: pe prima banda masinile se misca de la stanga spre dreapta si atunci pos_lane va arata la penultima pozitie de pe randul respectiv
; => deci la pozitia x=9, y=6 si cu formula z=11*y+x calculam pos_lane: z=66+9=75
pos_lane1 dd 75
pos_lane2 dd 78
pos_lane3 dd 97
pos_lane4 dd 100

; coordonatele din coltul stanga sus a celulei la care ne referim pentru fiecare banda
lane1_y dd 270
lane2_y dd 310
lane3_y dd 350
lane4_y dd 390

lane1_curr_x dd 545
lane1_next_x dd 605

lane2_curr_x dd 65
lane2_next_x dd 5

lane3_curr_x dd 545
lane3_next_x dd 605

lane4_curr_x dd 65
lane4_next_x dd 5

;in urmatoarele variabile voi stoca cate masini am in fiecare moment pe fiecare banda pentru a nu permite mai mult de:
lane1_nr_cars dd 0	;3 masini
lane2_nr_cars dd 0	;3 masini
lane3_nr_cars dd 0	;2 masini
lane4_nr_cars dd 0	;3 masini

;;;;;;;;;;;;;;;;;;;;;;;;;; variabile pentru miscarea bustenilor
pos_culoar1	dd 20
pos_culoar2	dd 23
pos_culoar3	dd 42
pos_culoar4	dd 45

culoar1_y	dd 70
culoar2_y	dd 110
culoar3_y	dd 150
culoar4_y	dd 190

culoar1_curr_x	dd 545
culoar1_next_x	dd 605

culoar2_curr_x	dd 65
culoar2_next_x	dd 5

culoar3_curr_x	dd 545
culoar3_next_x	dd 605

culoar4_curr_x	dd 65
culoar4_next_x	dd 5

culoar1_nr_logs	dd 0
culoar2_nr_logs	dd 0
culoar3_nr_logs	dd 0
culoar4_nr_logs	dd 0

;voi salva cati busteni se genereaza unul dupa altul. Nu vreau sa se genereze mai mult de 3 (sau 2) busteni unul dupa altul:
sequence_nr_logs2	dd 0  ; idee implementata doar pentru al doilea culoar



;pentru fereastra joc:
window_title DB "Froggy Game",0
area_width EQU 670
area_height EQU 500		;ratio de 3:2 a ferestrei jocului
area DD 0

counter DD 0 ; numara evenimentele de tip timer
count_calls dd 0; numara de cate ori se apeleaza procedura draw, pentru ca la fiecare al treilea apel sa mute masinile

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 EQU 24

;pentru text:
symbol_width EQU 10		
symbol_height EQU 20		
include digits.inc
include letters.inc

;pentru celulele din care e formata fereastra jocului: sunt 11 celule pe latime si 11 celule pe inaltime
cell_width 		equ	60
cell_height		equ	40
number_cells	equ	11		;dar reprezinta si latimea si inaltimea matricii matrice
stop_game 		db	0		;in momentul in care o sa castig sau o sa pierd, variabila o sa devina 1 ca sa nu se mai intample nimic cand se apeaza functia draw

;includ imaginile:
include water.inc	;apa
include heart.inc	;inima
include frog.inc	;broasca
include little_frog.inc	;broasca
include green_car_even.inc	;masina verde pe benzi pare
include mov_car_odd.inc		;masina mov pe benzi impare
include log_cell.inc		;bustean pe culoare impare 
include log_even.inc		;bustean pe culoare pare 


;culorile folosite:
light_grey 	equ 0B6B6B6h	;trotuar
dark_grey	equ 0898989h	;sosea
green 		equ 19EF18h		;refugii

var_4 dd 4
var_5 dd 5
var_11 dd 11

.code

fill_space_color_macro macro drawArea, x_beginning, y_beginning, x_end, y_end, color
	local colorare_pixel, inAfaraMatricii
		
		mov ecx, area_height*area_width		;ecx va tine ultimul pixel care se poate colora pt a controla daca iesim din matrice
		shl ecx, 2
		add ecx, drawArea
		
		; stabilesc punctul de plecare la colorare
		mov eax, y_beginning*area_width
		add eax, x_beginning
		shl eax, 2
		add eax, drawArea
		
		; stabilesc punctul in care sa se opreasca colorarea
		mov ebx, y_end*area_width
		add ebx, x_end
		shl ebx, 2
		add ebx, drawArea
		
	colorare_pixel:
		cmp eax, ecx			;teatam daca incercam sa coloram pixeli din afara matricii
		jg inAfaraMatricii
		mov dword ptr[eax], color
		add eax, 4
		cmp eax, ebx
		jle colorare_pixel
		
	inAfaraMatricii: 			;nu se intampla nimic si se termina colorarea
	
endm

line_horizontal_macro macro drawArea, x, y, len, color		
local coloreaza_pixel, inAfaraMatricii

		mov eax, y
		mov ebx, area_width
		mul ebx
		add eax, x
		shl eax, 2
		add eax, drawArea		;calculam locul primului pixel al liniei de colorat din matricea jocului  
		
		mov ebx, area_height*area_width		;ecx va tine ultimul pixel care se poate colora pt a controla daca iesim din matrice
		shl ebx, 2
		add ebx, drawArea
		
		mov ecx, len
		
	coloreaza_pixel:
		cmp eax, ebx			;teatam daca incercam sa coloram pixeli din afara matricii
		jg inAfaraMatricii
		
		mov edx, len			;in portiunea asta ma asigur ca nu trec cu lina mea de desenat de la capatul randului
		sub edx, ecx
		add edx, x
		cmp edx, area_width
		jge inAfaraMatricii
		
		mov dword ptr [eax], color
		add eax, 4
		loop coloreaza_pixel
		
	inAfaraMatricii:
endm

line_vertical_macro macro drawArea, x, y, len, color	
local coloreaza_pixel, inAfaraMatricii

		mov eax, y
		mov ebx, area_width
		mul ebx
		add eax, x
		shl eax, 2
		add eax, drawArea		;calculam locul primului pixel al liniei de colorat din matricea jocului  
		
		mov ebx, area_height*area_width		;ebx va tine ultimul pixel care se poate colora pt a controla daca iesim din matrice
		shl ebx, 2
		add ebx, drawArea
		
		mov ecx, len
		
		coloreaza_pixel:
		cmp eax, ebx			;teatam daca incercam sa coloram pixeli din afara matricii
		jg inAfaraMatricii
		
		mov dword ptr [eax], color
		add eax, area_width*4
		loop coloreaza_pixel
		
	inAfaraMatricii:
	
endm	
	
;va primi coordomatele (x,y) din coltul stanga sus a unui dreptunghi si lungimea si latimea dreptunghiului
fill_rectangle_macro macro drawArea, x, y, wid, heig, color 
local move_horizontal, move_vertical

		mov eax, y
		mov ebx, area_width
		mul ebx
		add eax, x
		shl eax, 2
		add eax, drawArea		;calculam locul primului pixel al liniei de colorat din matricea jocului  

		mov ebx, area_height*area_width		;ebx va tine ultimul pixel care se poate colora pt a controla daca iesim din matrice
		shl ebx, 2
		add ebx, drawArea
		
		mov edx, 0			;EDX contor pentru cate linii coloram
		
	move_vertical:
		mov ecx, wid		;ECX contor pt latime
		push eax			;pastrez locul primului pixel de pe randul respectiv
		
	move_horizontal:	
		mov dword ptr [eax], color
		add eax, 4
		
		loop move_horizontal
		
		pop eax
		add eax, area_width*4	;trec la locul primului pixel de pe urmatorul rand
		inc edx
		cmp edx, heig			
		jl move_vertical
		
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IMAGE SECTION:

; Make an image at the given coordinates:
; arg1 - x of drawing start position
; arg2 - y of drawing start position
; arg3 - effective adress of image to be drawn
; arg4 - image width
; arg5 - image height
make_image proc
		push ebp
		mov ebp, esp
		pusha

		mov esi,  [ebp+arg3]			;effective adress of image to be drawn
		
	draw_image:
		mov ecx, [ebp+arg5]			;image height
	loop_draw_lines:
		mov edi, area ; pointer to pixel area
		mov eax, [ebp+arg2] ; pointer to coordinate y
		
		add eax, [ebp+arg5]			;image height 
		sub eax, ecx ; current line to draw (total - ecx)
		
		mov ebx, area_width
		mul ebx	; get to current line
		
		add eax, [ebp+arg1] ; get to coordinate x in current line
		shl eax, 2 ; multiply by 4 (DWORD per pixel)
		add edi, eax
		
		push ecx
		mov ecx, [ebp+arg4]					;image width ; store drawing width for drawing loop
		
	loop_draw_columns:

		push eax
		mov eax, dword ptr[esi] 
		
		mov dword ptr [edi], eax ; take data from variable to canvas
		pop eax
		
		add esi, 4
		add edi, 4 ; next dword (4 Bytes)
		
		loop loop_draw_columns
		
		pop ecx
		loop loop_draw_lines
		popa
		
		mov esp, ebp
		pop ebp
		ret
make_image endp

; Make a trsnsparent image at the given coordinates:
;It is necessary that the background of the image passed to be white in order for it to be transparent
; arg1 - x of drawing start position
; arg2 - y of drawing start position
; arg3 - effective adress of image to be drawn
; arg4 - image width
; arg5 - image height
make_image_transparent proc
		push ebp
		mov ebp, esp
		pusha

		mov esi,  [ebp+arg3]			;effective adress of image to be drawn
		
	draw_image:
		mov ecx, [ebp+arg5]			;image height
	loop_draw_lines:
		mov edi, area ; pointer to pixel area
		mov eax, [ebp+arg2] ; pointer to coordinate y
		
		add eax, [ebp+arg5]			;image height 
		sub eax, ecx ; current line to draw (total - ecx)
		
		mov ebx, area_width
		mul ebx	; get to current line
		
		add eax, [ebp+arg1] ; get to coordinate x in current line
		shl eax, 2 ; multiply by 4 (DWORD per pixel)
		add edi, eax
		
		push ecx
		mov ecx, [ebp+arg4]					;image width ; store drawing width for drawing loop
		
	loop_draw_columns:
	
		cmp dword ptr[esi], 0ffffffh
		je dont_draw
		push eax
		mov eax, dword ptr[esi] 
		
		mov dword ptr [edi], eax ; take data from variable to canvas
		pop eax
		
	dont_draw:
		add esi, 4
		add edi, 4 ; next dword (4 Bytes)
		
		loop loop_draw_columns
		
		pop ecx
		loop loop_draw_lines
		popa
		
		mov esp, ebp
		pop ebp
		ret
make_image_transparent endp

; arg1 - coordinates of x
; arg2 - coordinates of y
make_image_water proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, water_0
		
		push water_0_h
		push water_0_w
		push esi
		push ebx
		push eax
		call make_image		;se deseneaza prima parte a imaginii
		add esp, 20
		
		lea esi, water_1
		add eax, water_0_w
		
		push water_1_h
		push water_1_w
		push esi
		push ebx
		push eax
		call make_image		;se deseneaza a doua parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_water endp

make_image_macro_water macro x, y		;;; 60x40
		push y
		push x
		call make_image_water
		add esp, 8
endm

make_image_heart proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, heart
		
		push heart_h
		push heart_w
		push esi
		push ebx
		push eax
		call make_image		;se deseneaza prima parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_heart endp

make_image_macro_heart macro x, y		;;; 30x30
		push y
		push x
		call make_image_heart
		add esp, 8
endm

make_image_little_frog proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, little_frog
		
		push little_frog_h
		push little_frog_w
		push esi
		push ebx
		push eax
		call make_image		;se deseneaza prima parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_little_frog endp

make_image_macro_little_frog macro x, y		;;; 25x25
		push y
		push x
		call make_image_little_frog
		add esp, 8
endm


make_image_frog proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, frog
		
		push frog_h
		push frog_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza prima parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_frog endp

make_image_macro_frog macro x, y		;;; 48x40
		push y
		push x
		call make_image_frog
		add esp, 8
endm

make_image_green_car_even proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, green_car_even_0
		
		push green_car_even_0_h
		push green_car_even_0_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza prima parte a imaginii
		add esp, 20
		
		lea esi, green_car_even_1
		add eax, green_car_even_0_w
		
		push green_car_even_1_h
		push green_car_even_1_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza a doua parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_green_car_even endp

make_image_macro_green_car_even macro x, y		;;; 60x40
		push y
		push x
		call make_image_green_car_even
		add esp, 8
endm

make_image_mov_car_odd proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, mov_car_odd_0
		
		push mov_car_odd_0_h
		push mov_car_odd_0_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza prima parte a imaginii
		add esp, 20
		
		lea esi, mov_car_odd_1
		add eax, mov_car_odd_0_w
		
		push mov_car_odd_1_h
		push mov_car_odd_1_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza a doua parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_mov_car_odd endp

make_image_macro_mov_car_odd macro x, y		;;; 60x40
		push y
		push x
		call make_image_mov_car_odd
		add esp, 8
endm

make_image_log proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, log_0
		
		push log_0_h
		push log_0_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza prima parte a imaginii
		add esp, 20
		
		lea esi, log_1
		add eax, log_0_w
		
		push log_1_h
		push log_1_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza a doua parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_log endp

make_image_macro_log macro x, y		;;; 60x40
		push y
		push x
		call make_image_log
		add esp, 8
endm

make_image_log_even proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]			;eax = coord. of x
		mov ebx, [ebp+arg2]			;ebx = coord. of y
		
		lea esi, log_even_0
		
		push log_even_0_h
		push log_even_0_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza prima parte a imaginii
		add esp, 20
		
		lea esi, log_even_1
		add eax, log_even_0_w
		
		push log_even_1_h
		push log_even_1_w
		push esi
		push ebx
		push eax
		call make_image_transparent		;se deseneaza a doua parte a imaginii
		add esp, 20
		
		popa
		mov esp, ebp
		pop ebp
		ret
make_image_log_even endp

make_image_macro_log_even macro x, y		;;; 60x40
		push y
		push x
		call make_image_log_even
		add esp, 8
endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;TEXT SECTION:

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1] ; citim simbolul de afisat
		cmp eax, 'A'
		jl make_digit
		cmp eax, 'Z'
		jg make_digit
		sub eax, 'A'
		lea esi, letters
		jmp draw_text
	make_digit:
		cmp eax, '0'
		jl make_space
		cmp eax, '9'
		jg make_space
		sub eax, '0'
		lea esi, digits
		jmp draw_text
	make_space:	
		mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
		lea esi, letters
		
	draw_text:
		mov ebx, symbol_width
		mul ebx
		mov ebx, symbol_height
		mul ebx
		add esi, eax
		mov ecx, symbol_height
	bucla_simbol_linii:
		mov edi, [ebp+arg2] ; pointer la matricea de pixeli
		mov eax, [ebp+arg4] ; pointer la coord y
		add eax, symbol_height
		sub eax, ecx
		mov ebx, area_width
		mul ebx
		add eax, [ebp+arg3] ; pointer la coord x
		shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
		add edi, eax
		push ecx
		mov ecx, symbol_width
	bucla_simbol_coloane:
		cmp byte ptr [esi], 0
		je simbol_pixel_alb
		mov dword ptr [edi], 0
		jmp simbol_pixel_next
	simbol_pixel_alb:
		mov dword ptr [edi], 0FFFFFFh
	simbol_pixel_next:
		inc esi
		add edi, 4
		loop bucla_simbol_coloane
		pop ecx
		loop bucla_simbol_linii
		popa
		mov esp, ebp
		pop ebp
		ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
		push y
		push x
		push drawArea
		push symbol
		call make_text
		add esp, 16
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_background_macro macro
		;liniile orizontale negre
		fill_space_color_macro area, 0, 0, 670, 29, 0
		fill_space_color_macro area, 0, 470, 670, 500, 0 ;cu 720 si 480 iasa afara din matrice, dar macroul are conditie sa nu depaseasca matricea asa ca e ok si cu mai mult
	
		;backgroundul:
		fill_rectangle_macro area, 65, 30, cell_width, cell_height, green		;verde
		fill_rectangle_macro area, 185, 30, cell_width, cell_height, green	;verde
		fill_rectangle_macro area, 305, 30, cell_width, cell_height, green	;verde
		fill_rectangle_macro area, 425, 30, cell_width, cell_height, green	;verde
		fill_rectangle_macro area, 545, 30, cell_width, cell_height, green	;verde
		fill_space_color_macro area, 5, 230, 664, 269, light_grey	;gri deschis
		fill_space_color_macro area, 5, 270, 664, 429, dark_grey	;gri inchis
		fill_space_color_macro area, 5, 430, 664, 469, light_grey	;gri deschis
		
		;linii sa arate mai bine:
		line_horizontal_macro area, 65, 69, cell_width, 0
		line_horizontal_macro area, 185, 69, cell_width, 0
		line_horizontal_macro area, 305, 69, cell_width, 0
		line_horizontal_macro area, 425, 69, cell_width, 0
		line_horizontal_macro area, 545, 69, cell_width, 0
		line_horizontal_macro area, 5, 230, 660, 0
		line_horizontal_macro area, 5, 270, 660, 0
		line_horizontal_macro area, 5, 310, 660, 0
		line_horizontal_macro area, 5, 350, 660, 0
		line_horizontal_macro area, 5, 390, 660, 0
		line_horizontal_macro area, 5, 430, 660, 0
		
		;liniile verticale negre:
		line_vertical_macro area, 0, 30, 440, 0
		line_vertical_macro area, 1, 30, 440, 0
		line_vertical_macro area, 2, 30, 440, 0
		line_vertical_macro area, 3, 30, 440, 0
		line_vertical_macro area, 4, 30, 440, 0
		line_vertical_macro area, 665, 30, 440, 0
		line_vertical_macro area, 666, 30, 440, 0
		line_vertical_macro area, 667, 30, 440, 0
		line_vertical_macro area, 668, 30, 440, 0
		line_vertical_macro area, 669, 30, 440, 0
		
		;apa:
		make_image_macro_water 5, 30
		make_image_macro_water 125, 30
		make_image_macro_water 245, 30
		make_image_macro_water 365, 30
		make_image_macro_water 485, 30
		make_image_macro_water 605, 30
		
		make_image_macro_water 5, 70
		make_image_macro_water 65, 70
		make_image_macro_water 125, 70
		make_image_macro_water 185, 70
		make_image_macro_water 245, 70
		make_image_macro_water 305, 70
		make_image_macro_water 365, 70
		make_image_macro_water 425, 70
		make_image_macro_water 485, 70
		make_image_macro_water 545, 70
		make_image_macro_water 605, 70
		
		make_image_macro_water 5, 110
		make_image_macro_water 65, 110
		make_image_macro_water 125, 110
		make_image_macro_water 185, 110
		make_image_macro_water 245, 110
		make_image_macro_water 305, 110
		make_image_macro_water 365, 110
		make_image_macro_water 425, 110
		make_image_macro_water 485, 110
		make_image_macro_water 545, 110
		make_image_macro_water 605, 110
		
		make_image_macro_water 5, 150
		make_image_macro_water 65, 150
		make_image_macro_water 125, 150
		make_image_macro_water 185, 150
		make_image_macro_water 245, 150
		make_image_macro_water 305, 150
		make_image_macro_water 365, 150
		make_image_macro_water 425, 150
		make_image_macro_water 485, 150
		make_image_macro_water 545, 150
		make_image_macro_water 605, 150
		
		make_image_macro_water 5, 190
		make_image_macro_water 65, 190
		make_image_macro_water 125, 190
		make_image_macro_water 185, 190
		make_image_macro_water 245, 190
		make_image_macro_water 305, 190
		make_image_macro_water 365, 190
		make_image_macro_water 425, 190
		make_image_macro_water 485, 190
		make_image_macro_water 545, 190
		make_image_macro_water 605, 190
		
		;inimi:
		make_image_macro_heart 515, 0
		make_image_macro_heart 545, 0
		make_image_macro_heart 575, 0
		make_image_macro_heart 605, 0
		make_image_macro_heart 635, 0
		
		;broaste ramase de pus in refugii:
		make_image_macro_little_frog 75, 2
		make_image_macro_little_frog 100, 2
		make_image_macro_little_frog 125, 2
		make_image_macro_little_frog 150, 2
		make_image_macro_little_frog 175, 2

		
		;broasca:
		make_image_macro_frog 305, 430
		
		;masinile initial pe drum:
		make_image_macro_mov_car_odd 185, 270
		mov matrice[69], 0
		inc lane1_nr_cars
		
		make_image_macro_mov_car_odd 5, 270
		mov matrice[66], 0
		inc lane1_nr_cars
		
		make_image_macro_green_car_even 125, 310
		mov matrice[79], 0
		inc lane2_nr_cars
		
		make_image_macro_green_car_even 305, 310
		mov matrice[82], 0
		inc lane2_nr_cars
		
		make_image_macro_green_car_even 485, 310
		mov matrice[85], 0
		inc lane2_nr_cars
		
		make_image_macro_mov_car_odd 185, 350
		mov matrice[91], 0
		inc lane3_nr_cars
		
		make_image_macro_mov_car_odd 425, 350
		mov matrice[95], 0
		inc lane3_nr_cars
		
		make_image_macro_green_car_even 185, 390
		mov matrice[102], 0
		inc lane4_nr_cars
		
		make_image_macro_green_car_even 305, 390
		mov matrice[104], 0
		inc lane4_nr_cars
		
		make_image_macro_green_car_even 605, 390
		mov matrice[109], 0
		inc lane4_nr_cars
		
		
		
		make_image_macro_log 65, 70
		mov matrice[12], 1
		inc culoar1_nr_logs
		
		make_image_macro_log 125, 70
		mov matrice[13], 1
		inc culoar1_nr_logs
		
		make_image_macro_log 365, 70
		mov matrice[17], 1
		inc culoar1_nr_logs
		
		make_image_macro_log_even 5, 110
		mov matrice[22], 1
		inc culoar2_nr_logs
		
		make_image_macro_log_even 185, 110
		mov matrice[25], 1
		inc culoar2_nr_logs
		
		make_image_macro_log_even 605, 110
		mov matrice[32], 1
		inc culoar2_nr_logs
		
		make_image_macro_log 185, 150
		mov matrice[36], 1
		inc culoar3_nr_logs
		
		make_image_macro_log 425, 150
		mov matrice[40], 1
		inc culoar3_nr_logs
		
		make_image_macro_log 485, 150
		mov matrice[41], 1
		inc culoar3_nr_logs
		
		make_image_macro_log_even 65, 190
		mov matrice[45], 1
		inc culoar4_nr_logs
		
		make_image_macro_log_even 185, 190
		mov matrice[47], 1
		inc culoar4_nr_logs
		
		make_image_macro_log_even 245, 190
		mov matrice[48], 1
		inc culoar4_nr_logs
		
		make_image_macro_log_even 305, 190
		mov matrice[49], 1
		inc culoar4_nr_logs
		
		make_image_macro_log_even 545, 190
		mov matrice[53], 1
		inc culoar4_nr_logs
		
endm

;coloreaza peste celula care incepe cu coordonatele (x,y) din coltul stanga sus
color_over_macro macro coord_x, coord_y
local light_grey_color, dark_grey_color, fill_space_et, water_color, macro_done
		cmp coord_y, 430
		jge light_grey_color
		cmp coord_y, 270
		jge dark_grey_color
		cmp coord_y, 230
		jge light_grey_color
		cmp coord_y, 70
		jge water_color
		
	light_grey_color:
		mov esi, light_grey
		jmp fill_space_et
	dark_grey_color:
		mov esi, dark_grey
		jmp fill_space_et
	
	fill_space_et:
		fill_rectangle_macro area, coord_x, coord_y, cell_width, cell_height, esi
		
		line_horizontal_macro area, coord_x, coord_y, cell_width, 0
		jmp macro_done
		
	water_color:
		make_image_macro_water coord_x, coord_y
		make_image_macro_log coord_x, coord_y
		
	macro_done:	
endm

; calculeaza deplasamentul fata de adresa de inceput a matricii pentru a ajunge la elementul de la coordonatele (idxx,idxy)
; va salva in variabila pos_frog rezultatul calculat
get_pos_frog_from_indices_macro macro idxx, idxy
		finit
		fild idxy
		fild var_11
		fmul
		fild idxx
		fadd
		fistp pos_frog
endm

respawn_macro macro
		mov frog_coord_x, 305
		mov frog_coord_y, 430
		make_image_macro_frog frog_coord_x, frog_coord_y	
		
		mov frog_index_x, 5
		mov frog_index_y, 10
		get_pos_frog_from_indices_macro frog_index_x, frog_index_y	;aici calculez deplasamentul pentru pozitia de respawn
		mov esi, pos_frog
		mov matrice[esi], 2
endm

you_won_macro macro
		fill_rectangle_macro area, 185, 190, 300, 120, 0
		make_text_macro 'Y', area, 300, 240
		make_text_macro 'O', area, 310, 240
		make_text_macro 'U', area, 320, 240
		make_text_macro 'W', area, 340, 240
		make_text_macro 'O', area, 350, 240
		make_text_macro 'N', area, 360, 240
		
		mov stop_game, 1
endm

wrong_move_macro macro
local not_over
		dec viata		
		finit 
		fild var_5
		fild viata
		fsub
		fild heart_w
		fmul
		fistp heart_block
		
		fill_rectangle_macro area, 515, 0, heart_block, heart_h, 0
		
		cmp viata, 0
		jne not_over
		game_over_macro
	not_over:
endm

game_over_macro macro
		fill_rectangle_macro area, 185, 190, 300, 120, 0
		make_text_macro 'G', area, 290, 240
		make_text_macro 'A', area, 300, 240
		make_text_macro 'M', area, 310, 240
		make_text_macro 'E', area, 320, 240
		make_text_macro 'O', area, 340, 240
		make_text_macro 'V', area, 350, 240
		make_text_macro 'E', area, 360, 240
		make_text_macro 'R', area, 370, 240
		
		mov stop_game, 1
endm

		;se verifica daca am sau nu masini pe o pozitie la timpul t pentru a o reprezenta la t+1
		;se verifica pt 10/11 celule de pe rand
		;pentru a 11-a celula se va stabili cu o formula daca acolo va aparea sau nu o noua masina
		;current serveste pentru verificare, next se modifica
movig_cars_macro macro
local no_car_last_position1, no_car_last_position2, no_car_last_position3, no_car_last_position4, shift_cars1, shift_cars2, shift_cars3, shift_cars4, no_car_case1, no_car_case2, no_car_case3, no_car_case4, car_case1, car_case2, car_case3, car_case4, continue_checking1, continue_checking2, continue_checking3, continue_checking4, reinitializare1, reinitializare2, reinitializare3, reinitializare4, final_draw
		
	;;;;LANE 1:
		mov esi, pos_lane1
		inc esi
		cmp matrice[esi], 0
		jne no_car_last_position1
		dec lane1_nr_cars
		
	no_car_last_position1:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_cars1:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_lane1		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		je car_case1
		; fie am 0=>car_case
		; fie am 1 sau 2 =>no_car_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_car_case1:
		cmp matrice[esi+1], 2	
		je continue_checking1	;daca pe pozitia next am broasca nu fac nimic si continui (nu pot desena sosea peste broasca, nu pot schimba valoarea in matrice de la next)
		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		fill_rectangle_macro area, lane1_next_x, lane1_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane1_next_x, lane1_y, cell_width, 0
		pop esi		;recuperez esi
		
		mov matrice[esi+1], 1
		jmp continue_checking1
	
	car_case1:
		push esi
		fill_rectangle_macro area, lane1_next_x, lane1_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane1_next_x, lane1_y, cell_width, 0
		make_image_macro_mov_car_odd lane1_next_x, lane1_y
		
		pop esi
		mov ebx, 0
		mov bl, matrice[esi+1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi+1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne continue_checking1
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
	
	continue_checking1:
		dec pos_lane1
		sub lane1_curr_x, cell_width
		sub lane1_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_cars1		
		; pana cand current=prima celula, next=a doua celula
		
		fill_rectangle_macro area, lane1_next_x, lane1_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane1_next_x, lane1_y, cell_width, 0
		mov esi, pos_lane1
		inc esi
		mov matrice[esi], 1
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp lane1_nr_cars, 4	
		jle generate1
		
		rdtsc
		test eax, 1
		jnz reinitializare1
		;altfel:
		
		cmp lane1_nr_cars, 3	;nu permit sa am mai mult de 3/11 masini pe banda
		jge reinitializare1
		
	generate1:
		inc lane1_nr_cars
		fill_rectangle_macro area, lane1_next_x, lane1_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane1_next_x, lane1_y, cell_width, 0
		make_image_macro_mov_car_odd lane1_next_x, lane1_y
		
		mov esi, pos_lane1
		mov ebx, 0
		mov bl, matrice[esi+1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi+1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne reinitializare1
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		
	reinitializare1:
		mov lane1_curr_x, 545
		mov lane1_next_x, 605
		mov pos_lane1, 75
		
		
	;;;;LANE 2:
		mov esi, pos_lane2
		dec esi
		cmp matrice[esi], 0
		jne no_car_last_position2
		dec lane2_nr_cars
		
	no_car_last_position2:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_cars2:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_lane2		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		je car_case2
		; fie am 0=>car_case
		; fie am 1 sau 2 =>no_car_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_car_case2:
		cmp matrice[esi-1], 2	
		je continue_checking2	;daca pe pozitia next am broasca nu fac nimic si continui (nu pot desena sosea peste broasca, nu pot schimba valoarea in matrice de la next)
		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		fill_rectangle_macro area, lane2_next_x, lane2_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane2_next_x, lane2_y, cell_width, 0
		pop esi		;recuperez esi
		
		mov matrice[esi-1], 1
		jmp continue_checking2
	
	car_case2:
		push esi
		fill_rectangle_macro area, lane2_next_x, lane2_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane2_next_x, lane2_y, cell_width, 0
		make_image_macro_green_car_even lane2_next_x, lane2_y
		
		pop esi
		mov ebx, 0
		mov bl, matrice[esi-1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi-1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne continue_checking2
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
	
	continue_checking2:
		inc pos_lane2
		add lane2_curr_x, cell_width
		add lane2_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_cars2		
		; pana cand current=prima celula, next=a doua celula
		
		fill_rectangle_macro area, lane2_next_x, lane2_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane2_next_x, lane2_y, cell_width, 0
		mov esi, pos_lane2
		dec esi
		mov matrice[esi], 1
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp lane2_nr_cars, 3	
		jle generate2
		
		rdtsc
		test eax, 1
		jnz reinitializare2
		;altfel:
		
		cmp lane2_nr_cars, 3	;nu permit sa am mai mult de 3/11 masini pe banda
		jge reinitializare2
		
	generate2:
		inc lane2_nr_cars
		fill_rectangle_macro area, lane2_next_x, lane2_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane2_next_x, lane2_y, cell_width, 0
		make_image_macro_green_car_even lane2_next_x, lane2_y
		
		mov esi, pos_lane2
		mov ebx, 0
		mov bl, matrice[esi-1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi-1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne reinitializare2
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		
	reinitializare2:
		mov lane2_curr_x, 65
		mov lane2_next_x, 5
		mov pos_lane2, 78
		
		
	;;;;LANE 3:
		mov esi, pos_lane3
		inc esi
		cmp matrice[esi], 0
		jne no_car_last_position3
		dec lane3_nr_cars
		
	no_car_last_position3:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_cars3:
	
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_lane3		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		je car_case3
		; fie am 0=>car_case
		; fie am 1 sau 2 =>no_car_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_car_case3:
		cmp matrice[esi+1], 2	
		je continue_checking3	;daca pe pozitia next am broasca nu fac nimic si continui (nu pot desena sosea peste broasca, nu pot schimba valoarea in matrice de la next)
		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		fill_rectangle_macro area, lane3_next_x, lane3_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane3_next_x, lane3_y, cell_width, 0
		pop esi		;recuperez esi
		
		mov matrice[esi+1], 1
		jmp continue_checking3
	
	car_case3:
		push esi
		fill_rectangle_macro area, lane3_next_x, lane3_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane3_next_x, lane3_y, cell_width, 0
		make_image_macro_mov_car_odd lane3_next_x, lane3_y		
		
		pop esi
		mov ebx, 0
		mov bl, matrice[esi+1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi+1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne continue_checking3
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
	
	continue_checking3:
		dec pos_lane3
		sub lane3_curr_x, cell_width
		sub lane3_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_cars3		
		; pana cand current=prima celula, next=a doua celula
		
		fill_rectangle_macro area, lane3_next_x, lane3_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane3_next_x, lane3_y, cell_width, 0
		mov esi, pos_lane3
		inc esi
		mov matrice[esi], 1
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp lane3_nr_cars, 2
		jle generate3
		
		rdtsc
		test eax, 1
		jnz reinitializare3
		;altfel:
		
		cmp lane3_nr_cars, 2	;nu permit sa am mai mult de 2/11 masini pe banda
		jge reinitializare3
		
	generate3:
		inc lane3_nr_cars
		fill_rectangle_macro area, lane3_next_x, lane3_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane3_next_x, lane3_y, cell_width, 0
		make_image_macro_mov_car_odd lane3_next_x, lane3_y
		
		mov esi, pos_lane3
		mov ebx, 0
		mov bl, matrice[esi+1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi+1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne reinitializare3
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		
	reinitializare3:
		mov lane3_curr_x, 545
		mov lane3_next_x, 605
		mov pos_lane3, 97
		
		
	;;;;LANE 4:
		mov esi, pos_lane4
		dec esi
		cmp matrice[esi], 0
		jne no_car_last_position4
		dec lane4_nr_cars
		
	no_car_last_position4:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_cars4:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_lane4		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		je car_case4
		; fie am 0=>car_case
		; fie am 1 sau 2 =>no_car_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_car_case4:
		cmp matrice[esi-1], 2	
		je continue_checking4	;daca pe pozitia next am broasca nu fac nimic si continui (nu pot desena sosea peste broasca, nu pot schimba valoarea in matrice de la next)
		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		fill_rectangle_macro area, lane4_next_x, lane4_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane4_next_x, lane4_y, cell_width, 0
		pop esi		;recuperez esi
		
		mov matrice[esi-1], 1
		jmp continue_checking4
	
	car_case4:
		push esi
		fill_rectangle_macro area, lane4_next_x, lane4_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane4_next_x, lane4_y, cell_width, 0
		make_image_macro_green_car_even lane4_next_x, lane4_y
		
		pop esi
		mov ebx, 0
		mov bl, matrice[esi-1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi-1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne continue_checking4
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
	
	continue_checking4:
		inc pos_lane4
		add lane4_curr_x, cell_width
		add lane4_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_cars4		
		; pana cand current=prima celula, next=a doua celula
		
		fill_rectangle_macro area, lane4_next_x, lane4_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane4_next_x, lane4_y, cell_width, 0
		mov esi, pos_lane4
		dec esi
		mov matrice[esi], 1
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp lane4_nr_cars, 2	
		jle generate4
		
		rdtsc
		test eax, 1
		jnz reinitializare4
		;altfel:
		
		cmp lane4_nr_cars, 3	;nu permit sa am mai mult de 3/11 masini pe banda
		jge reinitializare4
		
	generate4:
		inc lane4_nr_cars
		fill_rectangle_macro area, lane4_next_x, lane4_y, cell_width, cell_height, dark_grey
		line_horizontal_macro area, lane4_next_x, lane4_y, cell_width, 0
		make_image_macro_green_car_even lane4_next_x, lane4_y
		
		mov esi, pos_lane4
		mov ebx, 0
		mov bl, matrice[esi-1]	;voi tine minte valoarea care este acum la next in matrice pt ca o voi schimba in 0 si voi pierde informatia care imi spune daca acolo a fost o broasca
		mov matrice[esi-1], 0
		cmp ebx, 2	;verific daca inainte a fost o brosca pe next
		jne reinitializare4
		;altfel (daca da masina peste broasca)
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		
	reinitializare4:
		mov lane4_curr_x, 65
		mov lane4_next_x, 5
		mov pos_lane4, 100
		
	
	final_draw:
endm




moving_logs_macro1 macro 
local no_log_near1, no_frog_near_edge1, no_log_last_position1, shift_logs1, no_log_case1, log_case1, no_frog_on_log1, frog_on_log1, continue_checking1, generate1, reinitializare1, final_draw

;;;;CULOAR 1:
		mov esi, pos_culoar1
		inc esi
		
		cmp matrice[esi], 2
		jne no_frog_near_edge1
		; altfel daca avem broasca la margine:
		cmp matrice[esi-1], 1	;daca mai la dreapta este bustean atunci brosca se muta automat pe acel bustean, altfel pica in apa
		jne no_log_near1
		; daca este bustean langa
		mov matrice[esi-1], 2
		jmp no_frog_near_edge1
		
	no_log_near1:
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		;apoi executa ce e mai jos
		
	no_frog_near_edge1:	
		cmp matrice[esi], 0
		je no_log_last_position1
		dec culoar1_nr_logs
		
	no_log_last_position1:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_logs1:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_culoar1		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		jne log_case1
		; fie am 0=>log_case
		; fie am 1 sau 2 =>no_log_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_log_case1:		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		make_image_macro_water culoar1_next_x, culoar1_y
		pop esi		;recuperez esi
		
		mov matrice[esi+1], 0
		jmp continue_checking1
	
	log_case1:
		push esi
		make_image_macro_water culoar1_next_x, culoar1_y
		make_image_macro_log culoar1_next_x, culoar1_y
		pop esi
		
		cmp matrice[esi], 1
		je no_frog_on_log1
		
		cmp matrice[esi], 2
		je frog_on_log1
		
	no_frog_on_log1:
		mov matrice[esi+1], 1
		jmp continue_checking1
	
	frog_on_log1:
		mov matrice[esi+1], 2	; mut broasca
		inc frog_index_x		; modific index
		add frog_coord_x, cell_width	; modific coordonate
		make_image_macro_frog culoar1_next_x, culoar1_y
		
	
	continue_checking1:
		dec pos_culoar1
		sub culoar1_curr_x, cell_width
		sub culoar1_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_logs1		
		; pana cand current=prima celula, next=a doua celula
		
		make_image_macro_water culoar1_next_x, culoar1_y
		mov esi, pos_culoar1
		inc esi
		mov matrice[esi], 0
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp culoar1_nr_logs, 5
		jle generate1
		
		rdtsc
		test eax, 1
		jnz reinitializare1
		;altfel:
		
		cmp culoar1_nr_logs, 9	;nu permit sa am mai mult de 9/11 masini pe banda
		jge reinitializare1
		
	generate1:
		
		inc culoar1_nr_logs
		; make_image_macro_water culoar1_next_x, culoar1_y
		make_image_macro_log culoar1_next_x, culoar1_y
		
		mov esi, pos_culoar1
		mov matrice[esi+1], 1

	
	reinitializare1:
		mov culoar1_curr_x, 545
		mov culoar1_next_x, 605
		mov pos_culoar1, 20
		jmp final_draw

	final_draw:
endm

moving_logs_macro2 macro
local no_log_near2, no_frog_near_edge2, no_log_last_position2, shift_logs2, no_log_case2, log_case2, no_frog_on_log2, frog_on_log2, continue_checking2, reset_sequence2, generate2, reinitializare2, final_draw
		

;;;;CULOAR 2:
		mov esi, pos_culoar2
		dec esi
		
		cmp matrice[esi], 2
		jne no_frog_near_edge2
		; altfel daca avem broasca la margine:
		cmp matrice[esi+1], 1	;daca mai la dreapta este bustean atunci brosca se muta automat pe acel bustean, altfel pica in apa
		jne no_log_near2
		; daca este bustean langa
		mov matrice[esi+1], 2
		jmp no_frog_near_edge2
		
	no_log_near2:
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		;apoi executa ce e mai jos
		
	no_frog_near_edge2:	
		cmp matrice[esi], 0
		je no_log_last_position2
		dec culoar2_nr_logs
		
	no_log_last_position2:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_logs2:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_culoar2		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		jne log_case2
		; fie am 0=>log_case
		; fie am 1 sau 2 =>no_log_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_log_case2:		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		make_image_macro_water culoar2_next_x, culoar2_y
		pop esi		;recuperez esi
		
		mov matrice[esi-1], 0
		jmp continue_checking2
	
	log_case2:
		push esi
		make_image_macro_water culoar2_next_x, culoar2_y
		make_image_macro_log_even culoar2_next_x, culoar2_y
		pop esi
		
		cmp matrice[esi], 1
		je no_frog_on_log2
		
		cmp matrice[esi], 2
		je frog_on_log2
		
	no_frog_on_log2:
		mov matrice[esi-1], 1
		jmp continue_checking2
	
	frog_on_log2:
		mov matrice[esi-1], 2	; mut broasca
		dec frog_index_x		; modific index
		sub frog_coord_x, cell_width	; modific coordonate
		make_image_macro_frog culoar2_next_x, culoar2_y
		
	
	continue_checking2:
		inc pos_culoar2
		add culoar2_curr_x, cell_width
		add culoar2_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_logs2		
		; pana cand current=prima celula, next=a doua celula
		
		make_image_macro_water culoar2_next_x, culoar2_y
		mov esi, pos_culoar2
		dec esi
		mov matrice[esi], 0
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp culoar2_nr_logs, 4
		jle generate2
		
		rdtsc
		test eax, 1
		jnz reinitializare2
		;altfel:
		
		cmp culoar2_nr_logs, 7	;nu permit sa am mai mult de 6/11 masini pe banda
		jge reinitializare2
		
	generate2:
		inc culoar2_nr_logs
		; make_image_macro_water culoar2_next_x, culoar2_y
		make_image_macro_log_even culoar2_next_x, culoar2_y
		
		mov esi, pos_culoar2
		mov matrice[esi-1], 1
		jmp reinitializare2

	
	reinitializare2:
		mov culoar2_curr_x, 65
		mov culoar2_next_x, 5
		mov pos_culoar2, 23
		jmp final_draw
		
	final_draw:
endm



moving_logs_macro3 macro 
local no_log_near3, no_frog_near_edge3, no_log_last_position3, shift_logs3, no_log_case3, log_case3, no_frog_on_log3, frog_on_log3, continue_checking3, generate3, reinitializare3, final_draw

;;;;CULOAR 3:
		mov esi, pos_culoar3
		inc esi
		
		cmp matrice[esi], 2
		jne no_frog_near_edge3
		; altfel daca avem broasca la margine:
		cmp matrice[esi-1], 1	;daca mai la dreapta este bustean atunci brosca se muta automat pe acel bustean, altfel pica in apa
		jne no_log_near3
		; daca este bustean langa
		mov matrice[esi-1], 2
		jmp no_frog_near_edge3
		
	no_log_near3:
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		;apoi executa ce e mai jos
		
	no_frog_near_edge3:	
		cmp matrice[esi], 0
		je no_log_last_position3
		dec culoar3_nr_logs
		
	no_log_last_position3:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_logs3:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_culoar3		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		jne log_case3
		; fie am 0=>log_case
		; fie am 1 sau 2 =>no_log_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_log_case3:		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		make_image_macro_water culoar3_next_x, culoar3_y
		pop esi		;recuperez esi
		
		mov matrice[esi+1], 0
		jmp continue_checking3
	
	log_case3:
		push esi
		make_image_macro_water culoar3_next_x, culoar3_y
		make_image_macro_log culoar3_next_x, culoar3_y
		pop esi
		
		cmp matrice[esi], 1
		je no_frog_on_log3
		
		cmp matrice[esi], 2
		je frog_on_log3
		
	no_frog_on_log3:
		mov matrice[esi+1], 1
		jmp continue_checking3
	
	frog_on_log3:
		mov matrice[esi+1], 2	; mut broasca
		inc frog_index_x		; modific index
		add frog_coord_x, cell_width	; modific coordonate
		make_image_macro_frog culoar3_next_x, culoar3_y
		
	
	continue_checking3:
		dec pos_culoar3
		sub culoar3_curr_x, cell_width
		sub culoar3_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_logs3		
		; pana cand current=prima celula, next=a doua celula
		
		make_image_macro_water culoar3_next_x, culoar3_y
		mov esi, pos_culoar3
		inc esi
		mov matrice[esi], 0
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp culoar3_nr_logs, 5	
		jle generate3
		
		rdtsc
		test eax, 1
		jnz reinitializare3
		;altfel:
		
		cmp culoar3_nr_logs, 5	;nu permit sa am mai mult de 7/11 masini pe banda
		jge reinitializare3
		
	generate3:
		inc culoar3_nr_logs
		; make_image_macro_water culoar3_next_x, culoar3_y
		make_image_macro_log culoar3_next_x, culoar3_y
		
		mov esi, pos_culoar3
		mov matrice[esi+1], 1
	
	reinitializare3:
		mov culoar3_curr_x, 545
		mov culoar3_next_x, 605
		mov pos_culoar3, 42
		jmp final_draw

	final_draw:
endm

moving_logs_macro4 macro
local no_log_near4, no_frog_near_edge4, no_log_last_position4, shift_logs4, no_log_case4, log_case4, no_frog_on_log4, frog_on_log4, continue_checking4, generate4, reinitializare4, final_draw
		

;;;;CULOAR 4:
		mov esi, pos_culoar4
		dec esi
		
		cmp matrice[esi], 2
		jne no_frog_near_edge4
		; altfel daca avem broasca la margine:
		cmp matrice[esi+1], 1	;daca mai la dreapta este bustean atunci brosca se muta automat pe acel bustean, altfel pica in apa
		jne no_log_near4
		; daca este bustean langa
		mov matrice[esi+1], 2
		jmp no_frog_near_edge4
		
	no_log_near4:
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		respawn_macro
		;apoi executa ce e mai jos
		
	no_frog_near_edge4:	
		cmp matrice[esi], 0
		je no_log_last_position4
		dec culoar4_nr_logs
		
	no_log_last_position4:
		mov ecx, 10		;nuamrul de repetitii pentru o banda
		
	shift_logs4:
		push ecx	;pastrez pe stiva valoarea lui ecx pentru ca macrourile folosite mai jos modifica ecx
		mov esi, pos_culoar4		;deplasamentul pentru prima pozitie de verificat pt prima banda
		cmp matrice[esi], 0	
		jne log_case4
		; fie am 0=>log_case
		; fie am 1 sau 2 =>no_log_case (deci tratez cazul pe current=broasca la fel ca si cum nu as avea masina acolo)
		
	no_log_case4:		
		push esi	;pentru ca macroul sa nu schimbe valoarea esi 
		make_image_macro_water culoar4_next_x, culoar4_y
		pop esi		;recuperez esi
		
		mov matrice[esi-1], 0
		jmp continue_checking4
	
	log_case4:
		push esi
		make_image_macro_water culoar4_next_x, culoar4_y
		make_image_macro_log_even culoar4_next_x, culoar4_y
		pop esi
		
		cmp matrice[esi], 1
		je no_frog_on_log4
		
		cmp matrice[esi], 2
		je frog_on_log4
		
	no_frog_on_log4:
		mov matrice[esi-1], 1
		jmp continue_checking4
	
	frog_on_log4:
		mov matrice[esi-1], 2	; mut broasca
		dec frog_index_x		; modific index
		sub frog_coord_x, cell_width	; modific coordonate
		make_image_macro_frog culoar4_next_x, culoar4_y
		
	
	continue_checking4:
		inc pos_culoar4
		add culoar4_curr_x, cell_width
		add culoar4_next_x, cell_width
		
		pop ecx
		dec ecx
		cmp ecx, 0
		jg shift_logs4		
		; pana cand current=prima celula, next=a doua celula
		
		make_image_macro_water culoar4_next_x, culoar4_y
		mov esi, pos_culoar4
		dec esi
		mov matrice[esi], 0
	
		; stabilesc ce se intampla in prima celula (generez sau nu o noua masina):
		cmp culoar4_nr_logs, 3	
		jle generate4
		
		rdtsc
		test eax, 1
		jnz reinitializare4
		;altfel:
		
		cmp culoar4_nr_logs, 7	;nu permit sa am mai mult de 6/11 masini pe banda
		jge reinitializare4
		
	generate4:
		inc culoar4_nr_logs
		; make_image_macro_water culoar4_next_x, culoar4_y
		make_image_macro_log_even culoar4_next_x, culoar4_y
		
		mov esi, pos_culoar4
		mov matrice[esi-1], 1
	
	reinitializare4:
		mov culoar4_curr_x, 65
		mov culoar4_next_x, 5
		mov pos_culoar4, 45
		jmp final_draw
		
	final_draw:
endm



; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
		push ebp
		mov ebp, esp
		pusha

		cmp stop_game, 1
		je final_draw
		
		mov eax, [ebp+arg1]
		cmp eax, 2
		jz evt_timer ; nu s-a efectuat click pe nimic
		cmp eax, 1
		jz evt_click
		cmp eax, 3
		jz evt_keyboard
		
		;mai jos e codul care intializeaza fereastra cu pixeli albi
		mov eax, area_width
		mov ebx, area_height
		mul ebx
		shl eax, 2
		push eax
		push 255
		push area
		call memset
		add esp, 12
		
		make_background_macro
		
		jmp final_draw
		
		
	evt_click:	;consider click = move forward
		jmp move_up
		
	evt_timer:
		inc counter
		inc count_calls
		cmp count_calls, 4
		jg moment_to_move_cars
		jmp final_draw
		
		
	moment_to_move_cars:	
		mov count_calls, 0
		
		movig_cars_macro
		
		moving_logs_macro1
		moving_logs_macro2
		moving_logs_macro4
		moving_logs_macro3

		jmp final_draw
		
		
	evt_keyboard:
		mov eax, [ebp+arg2]		;pentru a afla directia de miscare
		cmp eax, 25h
		jl wrong_key
		cmp eax, 28h
		jg wrong_key
		
		cmp eax, 26h			;in sus
		je move_up
		cmp eax, 28h			;in jos
		je move_down
		cmp eax, 25h			;la stanga
		je move_left
		cmp eax, 27h			;la dreapta
		je move_right
		
	move_up:
		mov esi, frog_index_y
		dec esi
		mov check_index_y, esi
		get_pos_frog_from_indices_macro frog_index_x, check_index_y		;calculez deplasamentul
		mov esi, pos_frog
		
		cmp matrice[esi], 0
		je wrong_move
		
		cmp matrice[esi], 4
		je final_draw
		
		color_over_macro frog_coord_x, frog_coord_y
		sub frog_coord_y, cell_height
		make_image_macro_frog frog_coord_x, frog_coord_y	

		get_pos_frog_from_indices_macro frog_index_x, frog_index_y
		mov esi, pos_frog
		mov matrice[esi], 1			;schimb valoarea de pe pozitia precedenta in matrice
		
		dec frog_index_y
		
		get_pos_frog_from_indices_macro frog_index_x, frog_index_y	;aici calculez deplasamentul pentru pozitia pe care am ajuns
		mov esi, pos_frog
		
		cmp matrice[esi], 3
		je refugiu
		
		mov matrice[esi], 2		;se va executa doar daca in matrice la pozitia curenta avem 1
		jmp final_draw
		
	move_down:
		cmp frog_coord_y, 430	;daca este pe margine(jos) si vrea sa se miste in jos atunci nu face nimic
		jge final_draw
		
		mov esi, frog_index_y
		inc esi
		mov check_index_y, esi
		get_pos_frog_from_indices_macro frog_index_x, check_index_y		;calculez deplasamentul
		mov esi, pos_frog
		
		cmp matrice[esi], 0
		je wrong_move
		
		color_over_macro frog_coord_x, frog_coord_y
		add frog_coord_y, cell_height
		make_image_macro_frog frog_coord_x, frog_coord_y	

		get_pos_frog_from_indices_macro frog_index_x, frog_index_y
		mov esi, pos_frog
		mov matrice[esi], 1			;schimb valoarea de pe pozitia precedenta in matrice
		
		inc frog_index_y
		
		get_pos_frog_from_indices_macro frog_index_x, frog_index_y	;aici calculez deplasamentul pentru pozitia pe care am ajuns
		mov esi, pos_frog
		
		mov matrice[esi], 2		;se va executa doar daca in matrice la pozitia curenta avem 1
		jmp final_draw
	
	move_left:
		cmp frog_coord_x, 5
		jle final_draw		;daca este pe margine atunci nu face nimic
		
		mov esi, frog_index_x
		dec esi
		mov check_index_x, esi
		get_pos_frog_from_indices_macro check_index_x, frog_index_y		;calculez deplasamentul
		mov esi, pos_frog
		
		cmp matrice[esi], 0
		je wrong_move
		
		color_over_macro frog_coord_x, frog_coord_y
		sub frog_coord_x, cell_width
		make_image_macro_frog frog_coord_x, frog_coord_y	

		get_pos_frog_from_indices_macro frog_index_x, frog_index_y
		mov esi, pos_frog
		mov matrice[esi], 1			;schimb valoarea de pe pozitia precedenta in matrice
		
		dec frog_index_x
		
		get_pos_frog_from_indices_macro frog_index_x, frog_index_y	;aici calculez deplasamentul pentru pozitia pe care am ajuns
		mov esi, pos_frog
		
		mov matrice[esi], 2		;se va executa doar daca in matrice la pozitia curenta avem 1
		jmp final_draw
		
	move_right:
		cmp frog_coord_x, 605
		jge final_draw		;daca este pe margine atunci nu face nimic
		
		mov esi, frog_index_x
		inc esi
		mov check_index_x, esi
		get_pos_frog_from_indices_macro check_index_x, frog_index_y		;calculez deplasamentul
		mov esi, pos_frog
		
		cmp matrice[esi], 0
		je wrong_move
		
		color_over_macro frog_coord_x, frog_coord_y
		add frog_coord_x, cell_width
		make_image_macro_frog frog_coord_x, frog_coord_y	

		get_pos_frog_from_indices_macro frog_index_x, frog_index_y
		mov esi, pos_frog
		mov matrice[esi], 1			;schimb valoarea de pe pozitia precedenta in matrice
		
		inc frog_index_x
		
		get_pos_frog_from_indices_macro frog_index_x, frog_index_y	;aici calculez deplasamentul pentru pozitia pe care am ajuns
		mov esi, pos_frog
		
		mov matrice[esi], 2		;se va executa doar daca in matrice la pozitia curenta avem 1
		jmp final_draw
		
	refugiu:			;cazul in care ajungem pe 3 adica pe un refugiu
		mov matrice[esi], 4
		dec nr_broaste
		finit 
		fild var_5
		fild nr_broaste
		fsub
		fild little_frog_w
		fmul
		fistp little_frog_block
		
		fill_rectangle_macro area, 75, 2, little_frog_block, little_frog_h, 0
		
		cmp nr_broaste, 0
		je you_won_et
		;altfel:
		respawn_macro
		jmp final_draw
		
	you_won_et:
		you_won_macro
		jmp final_draw
		
		
	wrong_move:
		wrong_move_macro
		cmp stop_game, 1
		je final_draw	;daca e game over nu mai respawna
		;altfel:
		color_over_macro frog_coord_x, frog_coord_y
		get_pos_frog_from_indices_macro frog_index_x, frog_index_y
		mov esi, pos_frog
		mov matrice[esi], 1
		respawn_macro
		jmp final_draw
	
	
	wrong_key:
		jmp final_draw
	
	
	afisare_counter:
		;afisam valoarea counter-ului curent (sute, zeci si unitati)
		mov ebx, 10
		mov eax, counter
		;cifra unitatilor
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 30, 7
		;cifra zecilor
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 20, 7
		;cifra sutelor
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 10, 7
		jmp return_from_counter

	final_draw:
		jmp afisare_counter
	return_from_counter:
		popa
		mov esp, ebp
		pop ebp
		ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
