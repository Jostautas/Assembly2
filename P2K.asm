
.model small

FailBufDydis	EQU 50		;konstanta (lygi 50) - failu pavadinimu buferiu dydziai
skBufDydis	EQU 500		;konstanta - skaitymo buferio dydis
raBufDydis	EQU 50		;konstanta- rasymo buferio dydis

.stack 100h

.data

	pranesimas1	DB "ERROR", 10, 13, "$"
	pranesimas2	DB "Programa is duom failo visus simbolius pakeicia pagal duota lentele ir uzraso i rezultatu faila. Iveskite programos, duomenu ir rezultatu failu pavadinimus. PVZ: P2.exe duom.txt lenta.txt rez.txt", 10, 13, "$"
	input_failas	DB FailBufDydis dup (0)
	lent_failas	DB FailBufDydis dup (0)
	output_failas	DB FailBufDydis dup (0)
	skBuf	db skBufDydis dup (?)	;skaitymo buferis
	lenBuf	db skBufDydis dup (?)
	raBuf	db raBufDydis dup (0)
	dFail	dw ?			;vieta, skirta saugoti duomenu failo deskriptoriaus numeri ("handle") 
	lFail	dw ?
	rFail	dw ?

.code
Pradzia:
	MOV ax, @data
	MOV ds, ax		; Kad ds rodytu i duomenu segmento pradzia

	MOV ch, 0
	MOV cl, [es:80h]	; parametru simboliu skaicius
	CMP cx, 0
	JE error
	MOV bx, 81h

	MOV si, offset input_failas	
	JMP tikrinam_white_space1

help:
	MOV dx, offset pranesimas2
	MOV ah, 09h
	INT 21h
	
	JMP pabaiga
error:
	MOV dx, offset pranesimas1
	MOV ah, 09h
	INT 21h
	
	JMP pabaiga

tikrinam_duom:
	MOV ax, [es:bx]

	CMP ax, "?/"
	JE help

	CMP ah, " "
	JE tikrinam_lent

	MOV [si], ax
    
	INC bx
	INC si

	LOOP tikrinam_duom	; jei cl nelygu nuliui sokam i tikrinam_duom ir --cl

tikrinam_lent:	
	MOV si, offset lent_failas
	JMP tikrinam_white_space2
tikrinam_lent2:
	MOV ax, [es:bx]
    
	CMP ax, "?/"
	JE help

	CMP ah, " "
	je tikrinam_rez

	MOV [si], ax 

	INC bx
	INC si

	LOOP tikrinam_lent2

tikrinam_rez:
	MOV si, offset output_failas
	JMP tikrinam_white_space3

tikrinam_rez2:
	MOV ax, [es:bx]

	CMP ax, "?/"
	JE help
	
	CMP ah, 0Dh     ; CR - carrage return
	je toliau

	MOV [si], ax
    
	INC bx
	INC si

	LOOP tikrinam_rez2

	JMP toliau

error_jmp:
	JMP error

tikrinam_white_space1:
	MOV ax, [es:bx]
	CMP ah, " "
	JNE tikrinam_duom
	INC bx
	JMP tikrinam_white_space1
tikrinam_white_space2:
	MOV ax, [es:bx]
	CMP ah, " "
	JNE tikrinam_lent2
	INC bx
	JMP tikrinam_white_space2
tikrinam_white_space3:
	MOV ax, [es:bx]
	CMP ah, " "
	JNE tikrinam_rez2
	INC bx
	JMP tikrinam_white_space3

toliau:
	MOV ah, 3Dh			;failo atidarymo funkcijos numeris
	MOV al, 00			;00 - failas atidaromas skaitymui
	MOV dx, offset input_failas	;vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INC dx
	INT 21h				;failas atidaromas skaitymui
	JC error_jmp		;jei atidarant faila skaitymui ivyksta klaida, nustatomas carry flag
	MOV dFail, ax			;atmintyje issisaugom duomenu failo deskriptoriaus numeri    
	
	MOV ah, 3Dh			;failo atidarymo funkcijos numeris
	MOV al, 00			;00 - failas atidaromas skaitymui
	MOV dx, offset lent_failas	;vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INC dx
	INT 21h			;failas atidaromas skaitymui
	JC error_jmp	;jei atidarant faila skaitymui ivyksta klaida, nustatomas carry flag
	MOV lFail, ax		;atmintyje issisaugom duomenu failo deskriptoriaus numeri
	
	MOV ah, 3Ch		;21h pertraukimo failo sukurimo funkcijos numeris
	MOV cx, 0		;kuriamo failo atributai
	MOV dx, offset output_failas	;vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INC dx
	INT 21h			;sukuriamas failas; jei failas jau egzistuoja, visa jo informacija istrinama
	JC error_jmp		;jei kuriant faila skaitymui ivyksta klaida, nustatomas carry flag
	MOV rFail, ax		;atmintyje issisaugom rezultato failo deskriptoriaus numeri  
	
	MOV bx, dFail		;i bx irasom duomenu failo deskriptoriaus numeri
	CALL SkaitykBuf		;iskvieciame skaitymo is failo procedura
	MOV cx, ax          ; ax - kiek simboliu buvo nuskaityta
	
	MOV ah, 3Eh         ; uzdarom faila
	MOV bx, dFail
	INT 21h
	JC error_jmp
	 
	MOV bx, lFail
	CALL SkaitykBuf2
	
	MOV ah, 3Eh
	MOV bx, lFail
	INT 21h
	JC error_jmp 
	               
	               
	MOV si, offset skBuf
	MOV bx, offset raBuf
	PUSH cx
	MOV ax, 0	; kiek enter simboliu reiks ignoruot
	JMP print
	
error_jmp2:
	JMP error_jmp
	
newline:
	INC si
	INC ax
	JMP newline2

print:
	MOV di, offset lenBuf
	MOV dx, 0   
	ADD dl, byte ptr [si]   ; i dl isidedam duomenu failo simbolio koda
	CMP byte ptr [si], 20h	; tikrinam ar nenuskaitem nenorimu simboliu kaip pvz enter
	JB newline
	ADD di, dx              ; dl + lent.txt pradzios adresas
	MOV dl, byte ptr [di]   ; byte ptr di - naujo simbolio kodas
    
	MOV [bx], dl
	INC bx
	INC si
newline2:
	LOOP print
	POP cx
	SUB cx, ax
	
	MOV bx, rFail		;i bx irasom rezultato failo deskriptoriaus numeri
	CALL RasykBuf	;iskvieciame rasymo i faila procedura
	
	MOV ah, 3Eh
	MOV bx, rFail
	INT 21h
	JC error_jmp2
	
pabaiga:
	MOV ah, 4Ch
	INT 21h
	
error_jmp3:
	JMP error_jmp2
	
	
PROC SkaitykBuf
;i BX paduodamas failo deskriptoriaus numeris
;i AX bus grazinta, kiek simboliu nuskaityta
	PUSH cx
	PUSH dx
	
	MOV ah, 3Fh		;21h pertraukimo duomenu nuskaitymo funkcijos numeris
	MOV cx, skBufDydis	;cx - kiek baitu reikia nuskaityti is failo
	MOV dx, offset skBuf	;vieta, i kuria irasoma nuskaityta informacija
	INT 21h			;skaitymas is failo
	JC klaidaSkaitant	;jei skaitant is failo ivyksta klaida, nustatomas carry flag

  SkaitykBufPabaiga:
	POP dx
	POP cx
	RET

  klaidaSkaitant:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 0	;Pazymime registre ax, kad nebuvo nuskaityta ne vieno simbolio
	JMP SkaitykBufPabaiga
SkaitykBuf ENDP

PROC SkaitykBuf2
;i BX paduodamas failo deskriptoriaus numeris
;i AX bus grazinta, kiek simboliu nuskaityta
	PUSH cx
	PUSH dx

	MOV ah, 3Fh			;21h pertraukimo duomenu nuskaitymo funkcijos numeris
	MOV cx, skBufDydis		;cx - kiek baitu reikia nuskaityti is failo
	MOV dx, offset lenBuf	;vieta, i kuria irasoma nuskaityta informacija
	INT 21h			;skaitymas is failo
	JC klaidaSkaitant2		;jei skaitant is failo ivyksta klaida, nustatomas carry flag

  SkaitykBufPabaiga2:
	POP dx
	POP cx
	RET

  klaidaSkaitant2:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 0	;Pazymime registre ax, kad nebuvo nuskaityta ne vieno simbolio
	JMP SkaitykBufPabaiga2
SkaitykBuf2 ENDP

PROC RasykBuf
;i BX paduodamas failo deskriptoriaus numeris
;i CX - kiek baitu irasyti
;i AX bus grasinta, kiek baitu buvo irasyta
	PUSH dx

	MOV ah, 40h		;21h pertraukimo duomenu irasymo funkcijos numeris
	MOV dx, offset raBuf	;vieta, is kurios rasom i faila
	INT 21h			;rasymas i faila
	JC error_jmp2		;jei rasant i faila ivyksta klaida, nustatomas carry flag
	CMP cx, ax		;jei cx nelygus ax, vadinasi buvo irasyta tik dalis informacijos
	JNE error_jmp2

	POP dx
	RET
	
RasykBuf ENDP	
	
END Pradzia
