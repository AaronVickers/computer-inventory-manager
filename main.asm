%include "libio.asm"

global main

section .data
    ; Define max limits
    max_users equ 100
    max_computers equ 500
    
    ; Define user record field sizes
    size_forename equ 64
    size_surname equ 64
    size_department equ 64
    size_userid equ 9
    size_email equ 64
    
    ; Define computer record field sizes
    size_computername equ 64
    size_ipaddress equ 16
    size_os equ 64
    ; size_mainuserid equ size_userid ; No need for this, use size_userid instead
    size_date equ 11
    
    ; Forename: 64 bytes (63 characters + null)
    ; Surname: 64 bytes (63 characters + null)
    ; Department: 64 bytes (63 characters + null)
    ; User ID: 9 (p + 7 numbers + null)
    ; Email: 64 (48 characters + @helpdesk.co.uk (15 characters) + null)
    size_user_record equ size_forename + size_surname + size_department + size_userid + size_email
    size_user_array equ size_user_record * max_users
    
    ; Computer name: 9 bytes (c + 7 numbers + null)
    ; IP address: 16 bytes (XXX.XXX.XXX.XXX + null)
    ; Operating system: 64 bytes (63 characters + null)
    ; Main user ID: 9 (p + 7 numbers + null)
    ; Purchase date: 11 (DD.MM.YYYY + null)
    size_computer_record equ size_computername + size_ipaddress + size_os + size_userid + size_date
    size_computer_array equ size_computer_record * max_computers
    
    ; Define constant strings
    echo_prompt db "> ",0
    
    echo_opt_menu db "Select one of the following options:",10,\
                      "1. Add user",10,\
                      "2. Delete user",10,\
                      "3. Add computer",10,\
                      "4. Delete computer",10,\
                      "5. List users",10,\
                      "6. List computers",10,\
                      "7. Exit",10,0
    
    echo_forename db "Forename: ",0
    echo_surname db "Surname: ",0
    echo_department db "Department: ",0
    echo_userid db "User ID: ",0
    echo_email db "Email: ",0
    
    echo_computername db "Computer name: ",0
    echo_ipaddress db "IP address: ",0
    echo_os db "Operating system: ",0
    echo_mainuserid db "Main user ID: ",0
    echo_purchasedate db "Purchase date: ",0
    
    echo_user_added db "User added successfully!",0
    echo_user_deleted db "User deleted successfully!",0
    echo_computer_added db "Computer added successfully!",0
    echo_computer_deleted db "Computer deleted successfully!",0
    echo_goodbye db "Goodbye!",0
    
    warn_opt_invalid db "Invalid option selected!",0
    warn_input_invalid db "Invalid input!",0
    warn_userid_exists db "User with that ID already exists!",0
    warn_no_userid_exists db "User with that ID doesn't exist!",0
    warn_computername_exists db "Computer with that name already exists!",0
    warn_no_computername_exists db "Computer with that name doesn't exist!",0
    warn_storage_full db "Unable to complete action, storage is full!",0
    warn_no_users db "No users exist!",0
    warn_no_computers db "No computers exist!",0
    
    ; Define departments
    department_1 db "Development",0
    department_2 db "IT Support",0
    department_3 db "Finance",0
    department_4 db "HR",0
    
    ; Define OSs
    os_1 db "Windows",0
    os_2 db "Linux",0
    os_3 db "Mac OSX",0
    
    ; Email format
    email_format db "@helpdesk.co.uk",0
    
    ; Define counters
    user_count dq 0
    computer_count dq 0

section .bss
    ; Create uninitialised arrays
    user_array resb size_user_array
    computer_array resb size_computer_array
    
    ; Create input buffers for incomplete records
    user_record_buffer resb size_user_record
    computer_record_buffer resb size_computer_record

section .text

main:
    mov rbp, rsp; for correct debugging
    ; Compatablity
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    .options_loop:
        ; Print options menu and prompt
        mov rdi, echo_opt_menu
        call print_string_new
        mov rdi, echo_prompt
        call print_string_new
        
        call read_uint_new ; Get option from user
        
        ; Check option entered by user, jump to corresponding place
        cmp rax, 1
        je .add_user
        cmp rax, 2
        je .delete_user
        cmp rax, 3
        je .add_computer
        cmp rax, 4
        je .delete_computer
        cmp rax, 5
        je .list_users
        cmp rax, 6
        je .list_computers
        cmp rax, 7
        je exit
        
        ; Alert if option was invalid
        jmp .invalid_opt_input

    .add_user:
        ; Check if user storage is full
        mov rdx, [user_count]
        cmp rdx, max_users
        jge .storage_full
        
        mov rcx, user_record_buffer ; Put pointer to start of user record buffer in rcx
        
        ; Get forename
        mov rdi, echo_forename
        call print_string_new
        call read_string_new
        ; Validate forename
        call validate.forename
        cmp rbx, 0
        jz .invalid_input
        ; Copy forename to buffer
        mov rsi, rax
        lea rdi, [rcx]
        call copy_string
        
        ; Get surname
        mov rdi, echo_surname
        call print_string_new
        call read_string_new
        ; Validate surname
        call validate.surname
        cmp rbx, 0
        jz .invalid_input
        ; Copy surname to buffer
        mov rsi, rax
        lea rdi, [rcx + size_forename]
        call copy_string
        
        ; Get department
        mov rdi, echo_department
        call print_string_new
        call read_string_new
        ; Validate department
        call validate.department
        cmp rbx, 0
        jz .invalid_input
        ; Copy department to buffer
        mov rsi, rax
        lea rdi, [rcx + size_forename + size_surname]
        call copy_string
        
        ; Get user ID
        mov rdi, echo_userid
        call print_string_new
        call read_string_new
        ; Validate user ID
        call validate.userid
        cmp rbx, 0
        jz .invalid_input
        ; Make sure user ID is unique
        call does_userid_exist
        cmp rbx, 0
        jnz .userid_exists
        ; Copy user ID to buffer
        mov rsi, rax
        lea rdi, [rcx + size_forename + size_surname + size_department]
        call copy_string
        
        ; Get email
        mov rdi, echo_email
        call print_string_new
        call read_string_new
        ; Validate email
        call validate.email
        cmp rbx, 0
        jz .invalid_input
        ; Copy email to buffer
        mov rsi, rax
        lea rdi, [rcx + size_forename + size_surname + size_department + size_userid]
        call copy_string
        
        mov rcx, user_record_buffer ; Reset pointer to start of user record buffer
        
        ; Set up rdx to store address of next user
        mov rdx, [user_count] ; Move number of users to rdx
        imul rdx, size_user_record ; Multiply number of users by user record size
        add rdx, user_array ; Add initial address of user array
        
        ; Copy forename from user record buffer to user array
        lea rsi, [rcx]
        lea rdi, [rdx]
        call copy_string
        
        ; Copy surname from user record buffer to user array
        lea rsi, [rcx + size_forename]
        lea rdi, [rdx + size_forename]
        call copy_string
        
        ; Copy department from user record buffer to user array
        lea rsi, [rcx + size_forename + size_surname]
        lea rdi, [rdx + size_forename + size_surname]
        call copy_string
        
        ; Copy user ID from user record buffer to user array
        lea rsi, [rcx + size_forename + size_surname + size_department]
        lea rdi, [rdx + size_forename + size_surname + size_department]
        call copy_string
        
        ; Copy email from user record buffer to user array
        lea rsi, [rcx + size_forename + size_surname + size_department + size_userid]
        lea rdi, [rdx + size_forename + size_surname + size_department + size_userid]
        call copy_string
        
        inc QWORD [user_count] ; Increase user count
        
        ; Print user added successfully
        mov rdi, echo_user_added
        call print_string_new
        call print_nl_new
        call print_nl_new
        
        jmp .options_loop
    
    .delete_user:
        ; Get user ID
        mov rdi, echo_userid
        call print_string_new
        call read_string_new
        ; Validate user ID
        call validate.userid
        cmp rbx, 0
        jz .invalid_input
        
        ; Make sure user ID exists and get address
        call get_user_address
        cmp rbx, 0
        jz .no_userid_exists
        
        ; User record to delete is in rcx
        ; Put address of last user record in rdx
        mov rdx, [user_count] ; Move number of users to rdx
        dec rdx ; Subtract 1 to get last user record
        imul rdx, size_user_record ; Multiply number of users by user record size
        add rdx, user_array ; Add initial address of user array
        
        ; Overwrite forename
        lea rsi, [rdx]
        lea rdi, [rcx]
        call copy_string
        
        ; Overwrite surname
        lea rsi, [rdx + size_forename]
        lea rdi, [rcx + size_forename]
        call copy_string
        
        ; Overwrite department
        lea rsi, [rdx + size_forename + size_surname]
        lea rdi, [rcx + size_forename + size_surname]
        call copy_string
        
        ; Overwrite user ID
        lea rsi, [rdx + size_forename + size_surname + size_department]
        lea rdi, [rcx + size_forename + size_surname + size_department]
        call copy_string
        
        ; Overwrite email
        lea rsi, [rdx + size_forename + size_surname + size_department + size_userid]
        lea rdi, [rcx + size_forename + size_surname + size_department + size_userid]
        call copy_string
        
        dec QWORD [user_count] ; Decrease user count
        
        ; Print user deleted successfully
        mov rdi, echo_user_deleted
        call print_string_new
        call print_nl_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .add_computer:
        ; Check if computer storage is full
        mov rdx, [computer_count]
        cmp rdx, max_computers
        jge .storage_full
        
        mov rcx, computer_record_buffer ; Put pointer to start of computer record buffer in rcx
        
        ; Get computer name
        mov rdi, echo_computername
        call print_string_new
        call read_string_new
        ; Validate computer name
        call validate.computername
        cmp rbx, 0
        jz .invalid_input
        ; Make sure computer name is unique
        call does_computername_exist
        cmp rbx, 0
        jnz .computername_exists
        ; Copy computer name to buffer
        mov rsi, rax
        lea rdi, [rcx]
        call copy_string
        
        ; Get IP address
        mov rdi, echo_ipaddress
        call print_string_new
        call read_string_new
        ; Validate IP address
        call validate.ipaddress
        cmp rbx, 0
        jz .invalid_input
        ; Copy IP address to buffer
        mov rsi, rax
        lea rdi, [rcx + size_computername]
        call copy_string
        
        ; Get OS
        mov rdi, echo_os
        call print_string_new
        call read_string_new
        ; Validate OS
        call validate.os
        cmp rbx, 0
        jz .invalid_input
        ; Copy OS to buffer
        mov rsi, rax
        lea rdi, [rcx + size_computername + size_ipaddress]
        call copy_string
        
        ; Get main user ID
        mov rdi, echo_mainuserid
        call print_string_new
        call read_string_new
        ; Validate main user ID
        call validate.userid
        cmp rbx, 0
        jz .invalid_input
        ; Make sure main user ID exists
        call does_userid_exist
        cmp rbx, 0
        jz .no_userid_exists
        ; Copy user ID to buffer
        mov rsi, rax
        lea rdi, [rcx + size_computername + size_ipaddress + size_os]
        call copy_string
        
        ; Get purchase date
        mov rdi, echo_purchasedate
        call print_string_new
        call read_string_new
        ; Validate purchase date
        call validate.date
        cmp rbx, 0
        jz .invalid_input
        ; Copy purchase date to buffer
        mov rsi, rax
        lea rdi, [rcx + size_computername + size_ipaddress + size_os + size_userid]
        call copy_string
        
        mov rcx, computer_record_buffer ; Reset pointer to start of computer record buffer
        
        ; Set up rdx to store address of next computer
        mov rdx, [computer_count] ; Move number of computers to rdx
        imul rdx, size_computer_record ; Multiply number of computers by computer record size
        add rdx, computer_array ; Add initial address of computer array
        
        ; Copy computer name from computer record buffer to computer array
        lea rsi, [rcx]
        lea rdi, [rdx]
        call copy_string
        
        ; Copy IP address from computer record buffer to computer array
        lea rsi, [rcx + size_computername]
        lea rdi, [rdx + size_computername]
        call copy_string
        
        ; Copy OS from computer record buffer to computer array
        lea rsi, [rcx + size_computername + size_ipaddress]
        lea rdi, [rdx + size_computername + size_ipaddress]
        call copy_string
        
        ; Copy main user ID from computer record buffer to computer array
        lea rsi, [rcx + size_computername + size_ipaddress + size_os]
        lea rdi, [rdx + size_computername + size_ipaddress + size_os]
        call copy_string
        
        ; Copy purchase date from computer record buffer to computer array
        lea rsi, [rcx + size_computername + size_ipaddress + size_os + size_userid]
        lea rdi, [rdx + size_computername + size_ipaddress + size_os + size_userid]
        call copy_string
        
        inc QWORD [computer_count] ; Increase computer count
        
        ; Print computer added successfully
        mov rdi, echo_computer_added
        call print_string_new
        call print_nl_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .delete_computer:
        ; Get computer name
        mov rdi, echo_computername
        call print_string_new
        call read_string_new
        ; Validate computer name
        call validate.computername
        cmp rbx, 0
        jz .invalid_input
        
        ; Make sure computer name exists and get address
        call get_computer_address
        cmp rbx, 0
        jz .no_computername_exists
        
        ; Computer record to delete is in rcx
        ; Put address of last computer record in rdx
        mov rdx, [computer_count] ; Move number of computers to rdx
        dec rdx ; Subtract 1 to get last computer record
        imul rdx, size_computer_record ; Multiply number of computers by computer record size
        add rdx, computer_array ; Add initial address of computer array
        
        ; Overwrite computer name
        lea rsi, [rdx]
        lea rdi, [rcx]
        call copy_string
        
        ; Overwrite IP address
        lea rsi, [rdx + size_computername]
        lea rdi, [rcx + size_computername]
        call copy_string
        
        ; Overwrite OS
        lea rsi, [rdx + size_computername + size_ipaddress]
        lea rdi, [rcx + size_computername + size_ipaddress]
        call copy_string
        
        ; Overwrite main user ID
        lea rsi, [rdx + size_computername + size_ipaddress + size_os]
        lea rdi, [rcx + size_computername + size_ipaddress + size_os]
        call copy_string
        
        ; Overwrite date
        lea rsi, [rdx + size_computername + size_ipaddress + size_os + size_userid]
        lea rdi, [rcx + size_computername + size_ipaddress + size_os + size_userid]
        call copy_string
        
        dec QWORD [computer_count] ; Decrease computer count
        
        ; Print computer deleted successfully
        mov rdi, echo_computer_deleted
        call print_string_new
        call print_nl_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .list_users:
        mov rcx, user_array ; Set rcx to pointer at start of user array
        mov rdx, [user_count] ; Set rdx to value of user count
        
        call print_nl_new ; Print new line to separate output
        
        ; Check if no users exist
        cmp rdx, 0
        jz .list_users_none ; Jump if no users exist
        
        .list_users_loop:
            ; Check if listed all users
            cmp rdx, 0
            jz .list_users_exit ; Jump if listed all users
            
            ; Print forename
            mov rdi, echo_forename
            call print_string_new
            lea rdi, [rcx]
            call print_string_new
            call print_nl_new
            
            ; Print surname
            mov rdi, echo_surname
            call print_string_new
            lea rdi, [rcx + size_forename]
            call print_string_new
            call print_nl_new
            
            ; Print department
            mov rdi, echo_department
            call print_string_new
            lea rdi, [rcx + size_forename + size_surname]
            call print_string_new
            call print_nl_new
            
            ; Print user ID
            mov rdi, echo_userid
            call print_string_new
            lea rdi, [rcx + size_forename + size_surname + size_department]
            call print_string_new
            call print_nl_new
            
            ; Print email
            mov rdi, echo_email
            call print_string_new
            lea rdi, [rcx + size_forename + size_surname + size_department + size_userid]
            call print_string_new
            call print_nl_new
            
            call print_nl_new ; Print new line to separate output
            
            add rcx, size_user_record ; Update pointer to next user record
            dec rdx ; Decrease number of user records to list
            
            jmp .list_users_loop ; Loop for next user record
        
        .list_users_none:
            ; Warning when no users exist
            mov rdi, warn_no_users
            call print_string_new
            call print_nl_new
            call print_nl_new
        
        .list_users_exit:
            jmp .options_loop ; Return to options
    
    .list_computers:
        mov rcx, computer_array ; Set rcx to pointer at start of computer array
        mov rdx, [computer_count] ; Set rdx to value of computer count
        
        call print_nl_new ; Print new line to separate output
        
        ; Check if no computers exist
        cmp rdx, 0
        jz .list_computers_none ; Jump if no computers exist
        
        .list_computers_loop:
            ; Check if listed all computers
            cmp rdx, 0
            jz .list_computers_exit ; Jump if listed all computers
            
            ; Print computer name
            mov rdi, echo_computername
            call print_string_new
            lea rdi, [rcx]
            call print_string_new
            call print_nl_new
            
            ; Print IP address
            mov rdi, echo_ipaddress
            call print_string_new
            lea rdi, [rcx + size_computername]
            call print_string_new
            call print_nl_new
            
            ; Print OS
            mov rdi, echo_os
            call print_string_new
            lea rdi, [rcx + size_computername + size_ipaddress]
            call print_string_new
            call print_nl_new
            
            ; Print main user ID
            mov rdi, echo_mainuserid
            call print_string_new
            lea rdi, [rcx + size_computername + size_ipaddress + size_os]
            call print_string_new
            call print_nl_new
            
            ; Print purchase date
            mov rdi, echo_purchasedate
            call print_string_new
            lea rdi, [rcx + size_computername + size_ipaddress + size_os + size_userid]
            call print_string_new
            call print_nl_new
            
            call print_nl_new ; Print new line to separate output
            
            add rcx, size_computer_record ; Update pointer to next computer record
            dec rdx ; Decrease number of computer records to list
            
            jmp .list_computers_loop ; Loop for next computer record
        
        .list_computers_none:
            ; Warning when no computers exist
            mov rdi, warn_no_computers
            call print_string_new
            call print_nl_new
            call print_nl_new
        
        .list_computers_exit:
            jmp .options_loop ; Return to options
    
    .invalid_opt_input:
        ; Warning when invalid option is selected
        mov rdi, warn_opt_invalid
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .invalid_input:
        ; Warning when input could not be validated
        mov rdi, warn_input_invalid
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .userid_exists:
        ; Warning when an existing user ID is found
        mov rdi, warn_userid_exists
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .no_userid_exists:
        ; Warning when user ID cannot be found
        mov rdi, warn_no_userid_exists
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .computername_exists:
        ; Warning when an existing computer name is found
        mov rdi, warn_computername_exists
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .no_computername_exists:
        ; Warning when computer name cannot be found
        mov rdi, warn_no_computername_exists
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options
    
    .storage_full:
        ; Warning when storage is full
        mov rdi, warn_storage_full
        call print_string_new
        call print_nl_new
        
        jmp .options_loop ; Return to options

validate:
    ; Validates input in rax to meet criteria
    ; Sets rbx to 1 if valid
    ; Sets rbx to 0 if invalid
    
    .forename:
        ; 63 characters + null
        jmp .between_1_64_characters
    
    .surname:
        ; 63 characters + null
        jmp .between_1_64_characters
    
    .department:
        ; Development, IT Support, Finance, or HR
        ; Push used registers to stack
        push rax
        push rsi
        push rdi
        
        mov rsi, rax ; Put input department in rsi
        
        ; Check if matches department
        mov rdi, department_1
        call strings_are_equal
        cmp rax, 1
        jz .department_valid
        
        ; Check if matches department
        mov rdi, department_2
        call strings_are_equal
        cmp rax, 1
        jz .department_valid
        
        ; Check if matches department
        mov rdi, department_3
        call strings_are_equal
        cmp rax, 1
        jz .department_valid
        
        ; Check if matches department
        mov rdi, department_4
        call strings_are_equal
        cmp rax, 1
        jz .department_valid
        
        jmp .department_invalid ; Didn't match any department so invalid
        
        .department_valid:
            ; Restore registers from stack
            pop rdi
            pop rsi
            pop rax
            
            jmp .valid
        
        .department_invalid:
            ; Restore registers from stack
            pop rdi
            pop rsi
            pop rax
            
            jmp .invalid
    
    .userid:
        ; p + 7 numbers + null
        ; Check 1st character is p
        cmp BYTE [rax], 'p'
        jnz .invalid
        
        jmp .x_seven_numbers ; Jump to x + 7 numbers check
    
    .email:
        ; 48 characters + @helpdesk.co.uk (15 characters) + null
        mov rbx, 0 ; Character offset
        
        ; Loop over characters up to @
        .email_loop:
            ; Check character is @
            cmp BYTE [rax + rbx], '@'
            jz .email_loop_exit
            ; Check character is below valid character range
            cmp BYTE [rax + rbx], '!'
            jl .invalid
            ; Check character is above valid character range
            cmp BYTE [rax + rbx], '~'
            jg .invalid
            
            ; Increase counter to move to next character
            inc rbx
            
            ; Loop until 50th character
            cmp rbx, 49
            jnz .email_loop
            jmp .invalid ; Reached 49th character without @ so invalid
        
        .email_loop_exit:
            ; Make sure prefix length was > 0
            cmp rbx, 0
            jz .invalid
            
            ; Push used registers to stack
            push rax
            push rsi
            push rdi
            
            lea rsi, [rax + rbx] ; Put input email domain in rsi
            
            ; Check if matches email format
            mov rdi, email_format
            call strings_are_equal
            cmp rax, 1
            jz .email_valid
            
            jmp .email_invalid
        
        .email_valid:
            ; Restore registers from stack
            pop rdi
            pop rsi
            pop rax
            
            jmp .valid
        
        .email_invalid:
            ; Restore registers from stack
            pop rdi
            pop rsi
            pop rax
            
            jmp .invalid
    
    .computername:
        ; c + 7 numbers + null
        ; Check 1st character is c
        cmp BYTE [rax], 'c'
        jnz .invalid
        
        jmp .x_seven_numbers ; Jump to x + 7 numbers check
    
    .ipaddress:
        ; XXX.XXX.XXX.XXX + null
        ; Push used registers to stack
        push rbx
        push rsi
        push rdi
        
        mov rsi, '.' ; Move separator to rsi for finding index using find_char_in_string
        
        ; Check 1st octet validity
        lea rdi, [rax]
        call string_to_uint
        cmp rbx, 0
        jl .ipaddress_invalid
        cmp rbx, 255
        jg .ipaddress_invalid
        
        ; Get position of 1st period
        call find_char_in_string
        cmp rbx, 3
        jg .ipaddress_invalid
        
        ; Check 2nd octet validity
        lea rdi, [rdi + rbx + 1]
        call string_to_uint
        cmp rbx, 0
        jl .ipaddress_invalid
        cmp rbx, 255
        jg .ipaddress_invalid
        
        ; Get position of 2nd period
        call find_char_in_string
        cmp rbx, 3
        jg .ipaddress_invalid
        
        ; Check 3rd octet validity
        lea rdi, [rdi + rbx + 1]
        call string_to_uint
        cmp rbx, 0
        jl .ipaddress_invalid
        cmp rbx, 255
        jg .ipaddress_invalid
        
        ; Get position of 3rd period
        call find_char_in_string
        cmp rbx, 3
        jg .ipaddress_invalid
        
        ; Check 4th octet validity
        lea rdi, [rdi + rbx + 1]
        call string_to_uint
        cmp rbx, 0
        jl .ipaddress_invalid
        cmp rbx, 255
        jg .ipaddress_invalid
        
        .ipaddress_valid:
            pop rdi
            pop rsi
            pop rbx
            jmp .valid
        
        .ipaddress_invalid:
            pop rdi
            pop rsi
            pop rbx
            jmp .invalid
    
    .os:
        ; Linux, Windows, or Mac OSX
        ; Push used registers to stack
        push rax
        push rsi
        push rdi
        
        mov rsi, rax ; Put input OS in rsi
        
        ; Check if matches OS
        mov rdi, os_1
        call strings_are_equal
        cmp rax, 1
        jz .os_valid
        
        ; Check if matches OS
        mov rdi, os_2
        call strings_are_equal
        cmp rax, 1
        jz .os_valid
        
        ; Check if matches OS
        mov rdi, os_3
        call strings_are_equal
        cmp rax, 1
        jz .os_valid
        
        jmp .os_invalid ; Didn't match any OSs so invalid
        
        .os_valid:
            ; Restore registers from stack
            pop rdi
            pop rsi
            pop rax
            
            jmp .valid
        
        .os_invalid:
            ; Restore registers from stack
            pop rdi
            pop rsi
            pop rax
            
            jmp .invalid
    
    .date:
        ; DD.MM.YYYY + null
        ; Push used registers to stack
        push rbx
        push rsi
        push rdi

        ; Check format validity (DD.MM.YYYY)
        ; Check DD format
        ; 1st D
        cmp BYTE [rax], '0'
        jl .date_invalid
        cmp BYTE [rax], '9'
        jg .date_invalid
        ; 2nd D
        cmp BYTE [rax+1], '0'
        jl .date_invalid
        cmp BYTE [rax+1], '9'
        jg .date_invalid

        ; Check for 1st separator
        cmp BYTE [rax+2], '.'
        jnz .date_invalid

        ; Check MM format
        ; 1st M
        cmp BYTE [rax+3], '0'
        jl .date_invalid
        cmp BYTE [rax+3], '9'
        jg .date_invalid
        ; 2nd M
        cmp BYTE [rax+4], '0'
        jl .date_invalid
        cmp BYTE [rax+4], '9'
        jg .date_invalid

        ; Check for 2nd separator
        cmp BYTE [rax+5], '.'
        jnz .date_invalid

        ; Check YYYY format
        ; 1st Y
        cmp BYTE [rax+6], '0'
        jl .date_invalid
        cmp BYTE [rax+6], '9'
        jg .date_invalid
        ; 2nd Y
        cmp BYTE [rax+7], '0'
        jl .date_invalid
        cmp BYTE [rax+7], '9'
        jg .date_invalid
        ; 3rd Y
        cmp BYTE [rax+8], '0'
        jl .date_invalid
        cmp BYTE [rax+8], '9'
        jg .date_invalid
        ; 4th Y
        cmp BYTE [rax+9], '0'
        jl .date_invalid
        cmp BYTE [rax+9], '9'
        jg .date_invalid

        ; Check for null terminator
        cmp BYTE [rax+10], 0
        jnz .date_invalid
        
        ; Check DD validity
        lea rdi, [rax]
        call string_to_uint
        cmp rbx, 1
        jl .date_invalid
        cmp rbx, 31
        jg .date_invalid
        
        ; Check MM validity
        lea rdi, [rax + 3]
        call string_to_uint
        cmp rbx, 1
        jl .date_invalid
        cmp rbx, 12
        jg .date_invalid

        ; Check YYYY validity
        lea rdi, [rax + 6]
        call string_to_uint
        cmp rbx, 2000
        jl .date_invalid
        cmp rbx, 2100
        jg .date_invalid
        
        .date_valid:
            pop rdi
            pop rsi
            pop rbx
            jmp .valid
        
        .date_invalid:
            pop rdi
            pop rsi
            pop rbx
            jmp .invalid
    
    .between_1_64_characters:
        mov rbx, 0 ; Character offset
        
        ; Loop over characters until null or reached limit
        .between_1_64_characters_loop:
            ; Check character is null
            cmp BYTE [rax + rbx], 0
            jz .between_1_64_characters_loop_exit
            
            ; Increase counter to move to next character
            inc rbx
            
            ; Loop until 65th character
            cmp rbx, 64
            jnz .between_1_64_characters_loop
            
            jmp .invalid ; Null not found within 64 characters so invalid
        
        .between_1_64_characters_loop_exit:
            ; Make sure length was > 0
            cmp rbx, 0
            jz .invalid
            
            jmp .valid ; Length was between 1 and 64 characters so valid
    
    .x_seven_numbers:
        mov rbx, 1 ; Character offset
        
        ; Check characters 2-8 are number characters
        .seven_numbers_loop:
            ; Check character not below 0 character
            cmp BYTE [rax + rbx], '0'
            jl .invalid
            ; Check character not above 9 character
            cmp BYTE [rax + rbx], '9'
            jg .invalid
            
            ; Increase counter to move to next character
            inc rbx
            
            ; Loop until 9th character
            cmp rbx, 8
            jnz .seven_numbers_loop
        
        ; Check 9th character is null
        cmp BYTE [rax+rbx], 0
        jnz .invalid ; Invalid if not null
        
        jmp .valid ; All checks passed so valid
    
    .valid:
        mov rbx, 1
        ret
        
    .invalid:
        mov rbx, 0
        ret

get_user_address:
    ; Gets the address of user with supplied user ID in rax
    ; Sets rbx to 1 and rcx to user address if user with supplied user ID is found
    ; Sets rbx to 0 and rcx to last user address if user with supplied user ID is not found
    
    ; Push used registers to stack
    push rax
    push rdx
    push rdi
    push rsi
    
    mov rcx, user_array ; Set rcx to pointer at start of user array
    mov rdx, [user_count] ; Set rdx to value of user count
    
    mov rsi, rax ; Move supplied user ID to rsi register
    
    ; Check if no users exist
    cmp rdx, 0
    jz .not_found ; Jump if no users exist
    
    .scan_users_loop:
        ; Check if user ID is equal
        lea rdi, [rcx + size_forename + size_surname + size_department]
        call strings_are_equal ; Compare strings in rsi and rdi
        cmp rax, 1
        jz .found
        
        dec rdx ; Decrease number of user records to scan
        
        ; Check if listed all users
        cmp rdx, 0
        jz .not_found ; Jump if listed all users
        
        add rcx, size_user_record ; Update pointer to next user record
        jmp .scan_users_loop ; Loop for next user record
    
    .found:
        mov rbx, 1
        jmp .return
    
    .not_found:
        mov rbx, 0
        jmp .return
    
    .return:
        ; Restore registers from stack
        pop rsi
        pop rdi
        pop rdx
        pop rax
        
        ret

get_computer_address:
    ; Gets the address of computer with supplied computer name in rax
    ; Sets rbx to 1 and rcx to computer address if computer with supplied computer name is found
    ; Sets rbx to 0 and rcx to last computer address if computer with supplied computer name is not found
    
    ; Push used registers to stack
    push rax
    push rdx
    push rdi
    push rsi
    
    mov rcx, computer_array ; Set rcx to pointer at start of computer array
    mov rdx, [computer_count] ; Set rdx to value of computer count
    
    mov rsi, rax ; Move supplied computer name to rsi register
    
    ; Check if no computers exist
    cmp rdx, 0
    jz .not_found ; Jump if no computers exist
    
    .scan_computers_loop:
        ; Check if computer name is equal
        lea rdi, [rcx]
        call strings_are_equal ; Compare strings in rsi and rdi
        cmp rax, 1
        jz .found
        
        dec rdx ; Decrease number of computer records to scan
        
        ; Check if listed all computers
        cmp rdx, 0
        jz .not_found ; Jump if listed all computers
        
        add rcx, size_computer_record ; Update pointer to next computer record
        jmp .scan_computers_loop ; Loop for next computer record
    
    .found:
        mov rbx, 1 ; Store success state in rbx
        jmp .return
    
    .not_found:
        mov rbx, 0 ; Store success state in rbx
        jmp .return
    
    .return:
        ; Restore registers from stack
        pop rsi
        pop rdi
        pop rdx
        pop rax
        
        ret

does_userid_exist:
    ; Checks if user with supplied user ID in rax exists
    ; Sets rbx to 1 if user with supplied user ID is found
    ; Sets rbx to 0 if user with supplied user ID is not found
    
    ; Save state of rcx
    push rcx
    
    ; Call function to get user address which returns success in rbx
    call get_user_address
    
    ; Restore state of rcx
    pop rcx
    
    ret

does_computername_exist:
    ; Checks if computer with supplied computer name in rax exists
    ; Sets rbx to 1 if computer with supplied computer name is found
    ; Sets rbx to 0 if computer with supplied computer name is not found
    
    push rcx ; Save state of rcx
    
    call get_computer_address ; Call function to get computer address which returns success in rbx
    
    pop rcx ; Restore state of rcx
    
    ret

string_to_uint:
    ; Converts supplied string in rdi to unsigned integer up to first non-integer character
    ; Sets rbx to converted result
    
    ; Push used registers to stack
    push rcx
    push rdx
    
    mov rbx, 0 ; Result
    mov rcx, 0 ; Counter
    
    .string_to_uint_loop:
        movzx rdx, BYTE [rdi + rcx] ; Move character to rdx
        
        ; Check character is valid number
        cmp rdx, '0'
        jl .string_to_uint_loop_exit
        cmp rdx, '9'
        jg .string_to_uint_loop_exit
        
        imul rbx, 10 ; Multiple current result by 10
        sub rdx, '0' ; Get number value of character
        add rbx, rdx ; Add number value to result
        
        inc rcx ; Increase counter to next character
        
        jmp .string_to_uint_loop ; Loop for next character
    
    .string_to_uint_loop_exit:
        ; Restore registers from stack
        pop rdx
        pop rcx
        
        ret

find_char_in_string:
    ; Get index of first occurrence of character supplied in rsi in string in supplied in rdi
    ; Sets rbx to index of occurrence or -1 if not found
    
    ; Push used register to stack
    push rdx
    
    mov rbx, 0 ; Index
    
    .find_char_in_string_loop:
        movzx rdx, BYTE [rdi + rbx] ; Move character to rdx
        
        ; Check if characters match
        cmp rdx, rsi
        jz .find_char_in_string_loop_exit
        
        inc rbx ; Increase index to next character
        
        ; Check if reached null
        cmp rdx, 0
        jnz .find_char_in_string_loop ; Loop for next character
        
        ; Character not found by end of string so set rbx to -1
        mov rbx, -1
        jmp .find_char_in_string_loop_exit
    
    .find_char_in_string_loop_exit:
        ; Restore register from stack
        pop rdx
        
        ret

exit:
    ; Print goodbye message
    mov rdi, echo_goodbye
    call print_string_new
    call print_nl_new
    
    ; Compatability
    add rsp, 32
    pop rbp
    
    ret
