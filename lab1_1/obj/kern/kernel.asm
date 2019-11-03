
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1a 10 f0 	movl   $0xf0101a40,(%esp)
f0100055:	e8 d7 09 00 00       	call   f0100a31 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 24 07 00 00       	call   f01007ab <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1a 10 f0 	movl   $0xf0101a5c,(%esp)
f0100092:	e8 9a 09 00 00       	call   f0100a31 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 d2 14 00 00       	call   f0101597 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1a 10 f0 	movl   $0xf0101a77,(%esp)
f01000d9:	e8 53 09 00 00       	call   f0100a31 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 70 07 00 00       	call   f0100866 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 92 1a 10 f0 	movl   $0xf0101a92,(%esp)
f010012c:	e8 00 09 00 00       	call   f0100a31 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 c1 08 00 00       	call   f01009fe <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 d2 1d 10 f0 	movl   $0xf0101dd2,(%esp)
f0100144:	e8 e8 08 00 00       	call   f0100a31 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 11 07 00 00       	call   f0100866 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 aa 1a 10 f0 	movl   $0xf0101aaa,(%esp)
f0100176:	e8 b6 08 00 00       	call   f0100a31 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 74 08 00 00       	call   f01009fe <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 d2 1d 10 f0 	movl   $0xf0101dd2,(%esp)
f0100191:	e8 9b 08 00 00       	call   f0100a31 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 00 1b 10 f0 	mov    -0xfefe500(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 c4 1a 10 f0 	movl   $0xf0101ac4,(%esp)
f01002e9:	e8 43 07 00 00       	call   f0100a31 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 56 11 00 00       	call   f01015e4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 d0 1a 10 f0 	movl   $0xf0101ad0,(%esp)
f0100644:	e8 e8 03 00 00       	call   f0100a31 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 20 1d 10 	movl   $0xf0101d20,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 3e 1d 10 	movl   $0xf0101d3e,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 43 1d 10 f0 	movl   $0xf0101d43,(%esp)
f010069d:	e8 8f 03 00 00       	call   f0100a31 <cprintf>
f01006a2:	c7 44 24 08 2c 1e 10 	movl   $0xf0101e2c,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 4c 1d 10 	movl   $0xf0101d4c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 43 1d 10 f0 	movl   $0xf0101d43,(%esp)
f01006b9:	e8 73 03 00 00       	call   f0100a31 <cprintf>
f01006be:	c7 44 24 08 55 1d 10 	movl   $0xf0101d55,0x8(%esp)
f01006c5:	f0 
f01006c6:	c7 44 24 04 6c 1d 10 	movl   $0xf0101d6c,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 43 1d 10 f0 	movl   $0xf0101d43,(%esp)
f01006d5:	e8 57 03 00 00       	call   f0100a31 <cprintf>
	return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006e7:	c7 04 24 76 1d 10 f0 	movl   $0xf0101d76,(%esp)
f01006ee:	e8 3e 03 00 00       	call   f0100a31 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006fa:	00 
f01006fb:	c7 04 24 54 1e 10 f0 	movl   $0xf0101e54,(%esp)
f0100702:	e8 2a 03 00 00       	call   f0100a31 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 7c 1e 10 f0 	movl   $0xf0101e7c,(%esp)
f010071e:	e8 0e 03 00 00       	call   f0100a31 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 27 1a 10 	movl   $0x101a27,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 27 1a 10 	movl   $0xf0101a27,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 a0 1e 10 f0 	movl   $0xf0101ea0,(%esp)
f010073a:	e8 f2 02 00 00       	call   f0100a31 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 c4 1e 10 f0 	movl   $0xf0101ec4,(%esp)
f0100756:	e8 d6 02 00 00       	call   f0100a31 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 e8 1e 10 f0 	movl   $0xf0101ee8,(%esp)
f0100772:	e8 ba 02 00 00       	call   f0100a31 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100777:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010077c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100781:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100786:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010078c:	85 c0                	test   %eax,%eax
f010078e:	0f 48 c2             	cmovs  %edx,%eax
f0100791:	c1 f8 0a             	sar    $0xa,%eax
f0100794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100798:	c7 04 24 0c 1f 10 f0 	movl   $0xf0101f0c,(%esp)
f010079f:	e8 8d 02 00 00       	call   f0100a31 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
f01007ae:	57                   	push   %edi
f01007af:	56                   	push   %esi
f01007b0:	53                   	push   %ebx
f01007b1:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
        cprintf("Stack backtrace:\n");
f01007b4:	c7 04 24 8f 1d 10 f0 	movl   $0xf0101d8f,(%esp)
f01007bb:	e8 71 02 00 00       	call   f0100a31 <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007c0:	89 ee                	mov    %ebp,%esi
	unsigned int ebp,esp,eip;
	ebp=read_ebp();
	while(ebp){
f01007c2:	e9 8a 00 00 00       	jmp    f0100851 <mon_backtrace+0xa6>
		eip=*((unsigned int*)(ebp+4));
f01007c7:	8d 5e 04             	lea    0x4(%esi),%ebx
f01007ca:	8b 46 04             	mov    0x4(%esi),%eax
f01007cd:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		esp=ebp+4;
		cprintf("  ebp %08x  eip %08x  args",ebp,eip);
f01007d0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007d8:	c7 04 24 a1 1d 10 f0 	movl   $0xf0101da1,(%esp)
f01007df:	e8 4d 02 00 00       	call   f0100a31 <cprintf>
f01007e4:	8d 7e 18             	lea    0x18(%esi),%edi
                int i=0;
		for(i=0;i<5;i++)
		{
			esp+=4;
f01007e7:	83 c3 04             	add    $0x4,%ebx
			cprintf(" %08x",*(unsigned int*)esp);
f01007ea:	8b 03                	mov    (%ebx),%eax
f01007ec:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f0:	c7 04 24 bc 1d 10 f0 	movl   $0xf0101dbc,(%esp)
f01007f7:	e8 35 02 00 00       	call   f0100a31 <cprintf>
	while(ebp){
		eip=*((unsigned int*)(ebp+4));
		esp=ebp+4;
		cprintf("  ebp %08x  eip %08x  args",ebp,eip);
                int i=0;
		for(i=0;i<5;i++)
f01007fc:	39 fb                	cmp    %edi,%ebx
f01007fe:	75 e7                	jne    f01007e7 <mon_backtrace+0x3c>
			esp+=4;
			cprintf(" %08x",*(unsigned int*)esp);
		}

                struct Eipdebuginfo info;
		debuginfo_eip(eip,&info);
f0100800:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100803:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100807:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010080a:	89 3c 24             	mov    %edi,(%esp)
f010080d:	e8 16 03 00 00       	call   f0100b28 <debuginfo_eip>
                cprintf("\r\n");
f0100812:	c7 04 24 d1 1d 10 f0 	movl   $0xf0101dd1,(%esp)
f0100819:	e8 13 02 00 00       	call   f0100a31 <cprintf>
		cprintf("\t%s:%d: %.*s+%u\r\n",info.eip_file,
f010081e:	89 f8                	mov    %edi,%eax
f0100820:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100823:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100827:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010082a:	89 44 24 10          	mov    %eax,0x10(%esp)
f010082e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100831:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100835:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100838:	89 44 24 08          	mov    %eax,0x8(%esp)
f010083c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010083f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100843:	c7 04 24 c2 1d 10 f0 	movl   $0xf0101dc2,(%esp)
f010084a:	e8 e2 01 00 00       	call   f0100a31 <cprintf>
			info.eip_line,
			info.eip_fn_namelen,
			info.eip_fn_name,
			eip-info.eip_fn_addr); 

		ebp=*((unsigned int*)ebp);
f010084f:	8b 36                	mov    (%esi),%esi
{
	// Your code here.
        cprintf("Stack backtrace:\n");
	unsigned int ebp,esp,eip;
	ebp=read_ebp();
	while(ebp){
f0100851:	85 f6                	test   %esi,%esi
f0100853:	0f 85 6e ff ff ff    	jne    f01007c7 <mon_backtrace+0x1c>
			eip-info.eip_fn_addr); 

		ebp=*((unsigned int*)ebp);
	}
	return 0;
}
f0100859:	b8 00 00 00 00       	mov    $0x0,%eax
f010085e:	83 c4 4c             	add    $0x4c,%esp
f0100861:	5b                   	pop    %ebx
f0100862:	5e                   	pop    %esi
f0100863:	5f                   	pop    %edi
f0100864:	5d                   	pop    %ebp
f0100865:	c3                   	ret    

f0100866 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100866:	55                   	push   %ebp
f0100867:	89 e5                	mov    %esp,%ebp
f0100869:	57                   	push   %edi
f010086a:	56                   	push   %esi
f010086b:	53                   	push   %ebx
f010086c:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
        
        int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f010086f:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0100876:	00 
f0100877:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f010087e:	00 
f010087f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100886:	00 
f0100887:	c7 04 24 d4 1d 10 f0 	movl   $0xf0101dd4,(%esp)
f010088e:	e8 9e 01 00 00       	call   f0100a31 <cprintf>
	unsigned int i = 0x00646c72;
f0100893:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
        cprintf("H%x Wo%s", 57616, &i);
f010089a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010089d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008a1:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f01008a8:	00 
f01008a9:	c7 04 24 e6 1d 10 f0 	movl   $0xf0101de6,(%esp)
f01008b0:	e8 7c 01 00 00       	call   f0100a31 <cprintf>
        cprintf("\n");
f01008b5:	c7 04 24 d2 1d 10 f0 	movl   $0xf0101dd2,(%esp)
f01008bc:	e8 70 01 00 00       	call   f0100a31 <cprintf>

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008c1:	c7 04 24 38 1f 10 f0 	movl   $0xf0101f38,(%esp)
f01008c8:	e8 64 01 00 00       	call   f0100a31 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008cd:	c7 04 24 5c 1f 10 f0 	movl   $0xf0101f5c,(%esp)
f01008d4:	e8 58 01 00 00       	call   f0100a31 <cprintf>


	while (1) {
		buf = readline("K> ");
f01008d9:	c7 04 24 ef 1d 10 f0 	movl   $0xf0101def,(%esp)
f01008e0:	e8 5b 0a 00 00       	call   f0101340 <readline>
f01008e5:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	74 ee                	je     f01008d9 <monitor+0x73>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008eb:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008f2:	be 00 00 00 00       	mov    $0x0,%esi
f01008f7:	eb 0a                	jmp    f0100903 <monitor+0x9d>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008f9:	c6 03 00             	movb   $0x0,(%ebx)
f01008fc:	89 f7                	mov    %esi,%edi
f01008fe:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100901:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100903:	0f b6 03             	movzbl (%ebx),%eax
f0100906:	84 c0                	test   %al,%al
f0100908:	74 63                	je     f010096d <monitor+0x107>
f010090a:	0f be c0             	movsbl %al,%eax
f010090d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100911:	c7 04 24 f3 1d 10 f0 	movl   $0xf0101df3,(%esp)
f0100918:	e8 3d 0c 00 00       	call   f010155a <strchr>
f010091d:	85 c0                	test   %eax,%eax
f010091f:	75 d8                	jne    f01008f9 <monitor+0x93>
			*buf++ = 0;
		if (*buf == 0)
f0100921:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100924:	74 47                	je     f010096d <monitor+0x107>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100926:	83 fe 0f             	cmp    $0xf,%esi
f0100929:	75 16                	jne    f0100941 <monitor+0xdb>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010092b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100932:	00 
f0100933:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f010093a:	e8 f2 00 00 00       	call   f0100a31 <cprintf>
f010093f:	eb 98                	jmp    f01008d9 <monitor+0x73>
			return 0;
		}
		argv[argc++] = buf;
f0100941:	8d 7e 01             	lea    0x1(%esi),%edi
f0100944:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100948:	eb 03                	jmp    f010094d <monitor+0xe7>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010094a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010094d:	0f b6 03             	movzbl (%ebx),%eax
f0100950:	84 c0                	test   %al,%al
f0100952:	74 ad                	je     f0100901 <monitor+0x9b>
f0100954:	0f be c0             	movsbl %al,%eax
f0100957:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095b:	c7 04 24 f3 1d 10 f0 	movl   $0xf0101df3,(%esp)
f0100962:	e8 f3 0b 00 00       	call   f010155a <strchr>
f0100967:	85 c0                	test   %eax,%eax
f0100969:	74 df                	je     f010094a <monitor+0xe4>
f010096b:	eb 94                	jmp    f0100901 <monitor+0x9b>
			buf++;
	}
	argv[argc] = 0;
f010096d:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100974:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100975:	85 f6                	test   %esi,%esi
f0100977:	0f 84 5c ff ff ff    	je     f01008d9 <monitor+0x73>
f010097d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100982:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100985:	8b 04 85 a0 1f 10 f0 	mov    -0xfefe060(,%eax,4),%eax
f010098c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100990:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100993:	89 04 24             	mov    %eax,(%esp)
f0100996:	e8 61 0b 00 00       	call   f01014fc <strcmp>
f010099b:	85 c0                	test   %eax,%eax
f010099d:	75 24                	jne    f01009c3 <monitor+0x15d>
			return commands[i].func(argc, argv, tf);
f010099f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009a2:	8b 55 08             	mov    0x8(%ebp),%edx
f01009a5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01009a9:	8d 4d a4             	lea    -0x5c(%ebp),%ecx
f01009ac:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01009b0:	89 34 24             	mov    %esi,(%esp)
f01009b3:	ff 14 85 a8 1f 10 f0 	call   *-0xfefe058(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009ba:	85 c0                	test   %eax,%eax
f01009bc:	78 25                	js     f01009e3 <monitor+0x17d>
f01009be:	e9 16 ff ff ff       	jmp    f01008d9 <monitor+0x73>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009c3:	83 c3 01             	add    $0x1,%ebx
f01009c6:	83 fb 03             	cmp    $0x3,%ebx
f01009c9:	75 b7                	jne    f0100982 <monitor+0x11c>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009cb:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d2:	c7 04 24 15 1e 10 f0 	movl   $0xf0101e15,(%esp)
f01009d9:	e8 53 00 00 00       	call   f0100a31 <cprintf>
f01009de:	e9 f6 fe ff ff       	jmp    f01008d9 <monitor+0x73>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009e3:	83 c4 6c             	add    $0x6c,%esp
f01009e6:	5b                   	pop    %ebx
f01009e7:	5e                   	pop    %esi
f01009e8:	5f                   	pop    %edi
f01009e9:	5d                   	pop    %ebp
f01009ea:	c3                   	ret    

f01009eb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009eb:	55                   	push   %ebp
f01009ec:	89 e5                	mov    %esp,%ebp
f01009ee:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01009f4:	89 04 24             	mov    %eax,(%esp)
f01009f7:	e8 55 fc ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f01009fc:	c9                   	leave  
f01009fd:	c3                   	ret    

f01009fe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009fe:	55                   	push   %ebp
f01009ff:	89 e5                	mov    %esp,%ebp
f0100a01:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a04:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a0e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a12:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a15:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a19:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a1c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a20:	c7 04 24 eb 09 10 f0 	movl   $0xf01009eb,(%esp)
f0100a27:	e8 b2 04 00 00       	call   f0100ede <vprintfmt>
	return cnt;
}
f0100a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a2f:	c9                   	leave  
f0100a30:	c3                   	ret    

f0100a31 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a31:	55                   	push   %ebp
f0100a32:	89 e5                	mov    %esp,%ebp
f0100a34:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a37:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a3a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a41:	89 04 24             	mov    %eax,(%esp)
f0100a44:	e8 b5 ff ff ff       	call   f01009fe <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a49:	c9                   	leave  
f0100a4a:	c3                   	ret    

f0100a4b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a4b:	55                   	push   %ebp
f0100a4c:	89 e5                	mov    %esp,%ebp
f0100a4e:	57                   	push   %edi
f0100a4f:	56                   	push   %esi
f0100a50:	53                   	push   %ebx
f0100a51:	83 ec 10             	sub    $0x10,%esp
f0100a54:	89 c6                	mov    %eax,%esi
f0100a56:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a59:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a5c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a5f:	8b 1a                	mov    (%edx),%ebx
f0100a61:	8b 01                	mov    (%ecx),%eax
f0100a63:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a66:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a6d:	eb 77                	jmp    f0100ae6 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a72:	01 d8                	add    %ebx,%eax
f0100a74:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a79:	99                   	cltd   
f0100a7a:	f7 f9                	idiv   %ecx
f0100a7c:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a7e:	eb 01                	jmp    f0100a81 <stab_binsearch+0x36>
			m--;
f0100a80:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a81:	39 d9                	cmp    %ebx,%ecx
f0100a83:	7c 1d                	jl     f0100aa2 <stab_binsearch+0x57>
f0100a85:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a88:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a8d:	39 fa                	cmp    %edi,%edx
f0100a8f:	75 ef                	jne    f0100a80 <stab_binsearch+0x35>
f0100a91:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a94:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a97:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a9b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a9e:	73 18                	jae    f0100ab8 <stab_binsearch+0x6d>
f0100aa0:	eb 05                	jmp    f0100aa7 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100aa2:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100aa5:	eb 3f                	jmp    f0100ae6 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100aa7:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aaa:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100aac:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aaf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ab6:	eb 2e                	jmp    f0100ae6 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ab8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100abb:	73 15                	jae    f0100ad2 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100abd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100ac0:	48                   	dec    %eax
f0100ac1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ac4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ac7:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ac9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ad0:	eb 14                	jmp    f0100ae6 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ad2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ad5:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100ad8:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100ada:	ff 45 0c             	incl   0xc(%ebp)
f0100add:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100adf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ae6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ae9:	7e 84                	jle    f0100a6f <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100aeb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100aef:	75 0d                	jne    f0100afe <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100af1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100af4:	8b 00                	mov    (%eax),%eax
f0100af6:	48                   	dec    %eax
f0100af7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100afa:	89 07                	mov    %eax,(%edi)
f0100afc:	eb 22                	jmp    f0100b20 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100afe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b01:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b03:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b06:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b08:	eb 01                	jmp    f0100b0b <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b0a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b0b:	39 c1                	cmp    %eax,%ecx
f0100b0d:	7d 0c                	jge    f0100b1b <stab_binsearch+0xd0>
f0100b0f:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100b12:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100b17:	39 fa                	cmp    %edi,%edx
f0100b19:	75 ef                	jne    f0100b0a <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b1b:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100b1e:	89 07                	mov    %eax,(%edi)
	}
}
f0100b20:	83 c4 10             	add    $0x10,%esp
f0100b23:	5b                   	pop    %ebx
f0100b24:	5e                   	pop    %esi
f0100b25:	5f                   	pop    %edi
f0100b26:	5d                   	pop    %ebp
f0100b27:	c3                   	ret    

f0100b28 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b28:	55                   	push   %ebp
f0100b29:	89 e5                	mov    %esp,%ebp
f0100b2b:	57                   	push   %edi
f0100b2c:	56                   	push   %esi
f0100b2d:	53                   	push   %ebx
f0100b2e:	83 ec 3c             	sub    $0x3c,%esp
f0100b31:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b34:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b37:	c7 03 c4 1f 10 f0    	movl   $0xf0101fc4,(%ebx)
	info->eip_line = 0;
f0100b3d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b44:	c7 43 08 c4 1f 10 f0 	movl   $0xf0101fc4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b4b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b52:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b55:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b5c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b62:	76 12                	jbe    f0100b76 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b64:	b8 05 75 10 f0       	mov    $0xf0107505,%eax
f0100b69:	3d dd 5b 10 f0       	cmp    $0xf0105bdd,%eax
f0100b6e:	0f 86 c5 01 00 00    	jbe    f0100d39 <debuginfo_eip+0x211>
f0100b74:	eb 1c                	jmp    f0100b92 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b76:	c7 44 24 08 ce 1f 10 	movl   $0xf0101fce,0x8(%esp)
f0100b7d:	f0 
f0100b7e:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b85:	00 
f0100b86:	c7 04 24 db 1f 10 f0 	movl   $0xf0101fdb,(%esp)
f0100b8d:	e8 66 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b92:	80 3d 04 75 10 f0 00 	cmpb   $0x0,0xf0107504
f0100b99:	0f 85 a1 01 00 00    	jne    f0100d40 <debuginfo_eip+0x218>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b9f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ba6:	b8 dc 5b 10 f0       	mov    $0xf0105bdc,%eax
f0100bab:	2d 10 22 10 f0       	sub    $0xf0102210,%eax
f0100bb0:	c1 f8 02             	sar    $0x2,%eax
f0100bb3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bb9:	83 e8 01             	sub    $0x1,%eax
f0100bbc:	89 45 e0             	mov    %eax,-0x20(%ebp)
        

        stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0100bbf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bc3:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100bca:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bcd:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bd0:	b8 10 22 10 f0       	mov    $0xf0102210,%eax
f0100bd5:	e8 71 fe ff ff       	call   f0100a4b <stab_binsearch>
	if(lline>rline)
f0100bda:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bdd:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100be0:	0f 8f 61 01 00 00    	jg     f0100d47 <debuginfo_eip+0x21f>
	{
		return -1;
	}
	else
	{
	  info->eip_line=stabs[lline].n_desc;
f0100be6:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100be9:	0f b7 80 16 22 10 f0 	movzwl -0xfefddea(%eax),%eax
f0100bf0:	89 43 04             	mov    %eax,0x4(%ebx)
	}
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bf3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bf7:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bfe:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c01:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c04:	b8 10 22 10 f0       	mov    $0xf0102210,%eax
f0100c09:	e8 3d fe ff ff       	call   f0100a4b <stab_binsearch>
	if (lfile == 0)
f0100c0e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c11:	85 c0                	test   %eax,%eax
f0100c13:	0f 84 35 01 00 00    	je     f0100d4e <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c19:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c1f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c22:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c26:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c2d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c30:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c33:	b8 10 22 10 f0       	mov    $0xf0102210,%eax
f0100c38:	e8 0e fe ff ff       	call   f0100a4b <stab_binsearch>

	if (lfun <= rfun) {
f0100c3d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c40:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c43:	39 d0                	cmp    %edx,%eax
f0100c45:	7f 35                	jg     f0100c7c <debuginfo_eip+0x154>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c47:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c4a:	8d b1 10 22 10 f0    	lea    -0xfefddf0(%ecx),%esi
f0100c50:	8b 89 10 22 10 f0    	mov    -0xfefddf0(%ecx),%ecx
f0100c56:	bf 05 75 10 f0       	mov    $0xf0107505,%edi
f0100c5b:	81 ef dd 5b 10 f0    	sub    $0xf0105bdd,%edi
f0100c61:	39 f9                	cmp    %edi,%ecx
f0100c63:	73 09                	jae    f0100c6e <debuginfo_eip+0x146>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c65:	81 c1 dd 5b 10 f0    	add    $0xf0105bdd,%ecx
f0100c6b:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c6e:	8b 4e 08             	mov    0x8(%esi),%ecx
f0100c71:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
		// Search within the function definition for the line number.
		lline = lfun;
f0100c74:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c77:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c7a:	eb 0f                	jmp    f0100c8b <debuginfo_eip+0x163>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c7c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c88:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c8b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c92:	00 
f0100c93:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c96:	89 04 24             	mov    %eax,(%esp)
f0100c99:	e8 dd 08 00 00       	call   f010157b <strfind>
f0100c9e:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ca1:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ca7:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100caa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cad:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100cb0:	81 c2 10 22 10 f0    	add    $0xf0102210,%edx
f0100cb6:	eb 06                	jmp    f0100cbe <debuginfo_eip+0x196>
f0100cb8:	83 e8 01             	sub    $0x1,%eax
f0100cbb:	83 ea 0c             	sub    $0xc,%edx
f0100cbe:	89 c6                	mov    %eax,%esi
f0100cc0:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cc3:	7f 33                	jg     f0100cf8 <debuginfo_eip+0x1d0>
	       && stabs[lline].n_type != N_SOL
f0100cc5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100cc9:	80 f9 84             	cmp    $0x84,%cl
f0100ccc:	74 0b                	je     f0100cd9 <debuginfo_eip+0x1b1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cce:	80 f9 64             	cmp    $0x64,%cl
f0100cd1:	75 e5                	jne    f0100cb8 <debuginfo_eip+0x190>
f0100cd3:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100cd7:	74 df                	je     f0100cb8 <debuginfo_eip+0x190>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cd9:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100cdc:	8b 86 10 22 10 f0    	mov    -0xfefddf0(%esi),%eax
f0100ce2:	ba 05 75 10 f0       	mov    $0xf0107505,%edx
f0100ce7:	81 ea dd 5b 10 f0    	sub    $0xf0105bdd,%edx
f0100ced:	39 d0                	cmp    %edx,%eax
f0100cef:	73 07                	jae    f0100cf8 <debuginfo_eip+0x1d0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cf1:	05 dd 5b 10 f0       	add    $0xf0105bdd,%eax
f0100cf6:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cf8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cfb:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cfe:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d03:	39 ca                	cmp    %ecx,%edx
f0100d05:	7d 53                	jge    f0100d5a <debuginfo_eip+0x232>
		for (lline = lfun + 1;
f0100d07:	8d 42 01             	lea    0x1(%edx),%eax
f0100d0a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d0d:	89 c2                	mov    %eax,%edx
f0100d0f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d12:	05 10 22 10 f0       	add    $0xf0102210,%eax
f0100d17:	89 ce                	mov    %ecx,%esi
f0100d19:	eb 04                	jmp    f0100d1f <debuginfo_eip+0x1f7>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d1b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d1f:	39 d6                	cmp    %edx,%esi
f0100d21:	7e 32                	jle    f0100d55 <debuginfo_eip+0x22d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d23:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100d27:	83 c2 01             	add    $0x1,%edx
f0100d2a:	83 c0 0c             	add    $0xc,%eax
f0100d2d:	80 f9 a0             	cmp    $0xa0,%cl
f0100d30:	74 e9                	je     f0100d1b <debuginfo_eip+0x1f3>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d32:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d37:	eb 21                	jmp    f0100d5a <debuginfo_eip+0x232>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d3e:	eb 1a                	jmp    f0100d5a <debuginfo_eip+0x232>
f0100d40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d45:	eb 13                	jmp    f0100d5a <debuginfo_eip+0x232>
        

        stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
	if(lline>rline)
	{
		return -1;
f0100d47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d4c:	eb 0c                	jmp    f0100d5a <debuginfo_eip+0x232>
	{
	  info->eip_line=stabs[lline].n_desc;
	}
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d53:	eb 05                	jmp    f0100d5a <debuginfo_eip+0x232>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d5a:	83 c4 3c             	add    $0x3c,%esp
f0100d5d:	5b                   	pop    %ebx
f0100d5e:	5e                   	pop    %esi
f0100d5f:	5f                   	pop    %edi
f0100d60:	5d                   	pop    %ebp
f0100d61:	c3                   	ret    
f0100d62:	66 90                	xchg   %ax,%ax
f0100d64:	66 90                	xchg   %ax,%ax
f0100d66:	66 90                	xchg   %ax,%ax
f0100d68:	66 90                	xchg   %ax,%ax
f0100d6a:	66 90                	xchg   %ax,%ax
f0100d6c:	66 90                	xchg   %ax,%ax
f0100d6e:	66 90                	xchg   %ax,%ax

f0100d70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d70:	55                   	push   %ebp
f0100d71:	89 e5                	mov    %esp,%ebp
f0100d73:	57                   	push   %edi
f0100d74:	56                   	push   %esi
f0100d75:	53                   	push   %ebx
f0100d76:	83 ec 3c             	sub    $0x3c,%esp
f0100d79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d7c:	89 d7                	mov    %edx,%edi
f0100d7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d81:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d87:	89 c3                	mov    %eax,%ebx
f0100d89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d8c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d8f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d92:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d97:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d9a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d9d:	39 d9                	cmp    %ebx,%ecx
f0100d9f:	72 05                	jb     f0100da6 <printnum+0x36>
f0100da1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100da4:	77 69                	ja     f0100e0f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100da6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100da9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100dad:	83 ee 01             	sub    $0x1,%esi
f0100db0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100db4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100db8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dbc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100dc0:	89 c3                	mov    %eax,%ebx
f0100dc2:	89 d6                	mov    %edx,%esi
f0100dc4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100dc7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100dca:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100dd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd5:	89 04 24             	mov    %eax,(%esp)
f0100dd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ddb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ddf:	e8 bc 09 00 00       	call   f01017a0 <__udivdi3>
f0100de4:	89 d9                	mov    %ebx,%ecx
f0100de6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100dea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dee:	89 04 24             	mov    %eax,(%esp)
f0100df1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100df5:	89 fa                	mov    %edi,%edx
f0100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dfa:	e8 71 ff ff ff       	call   f0100d70 <printnum>
f0100dff:	eb 1b                	jmp    f0100e1c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e01:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e05:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e08:	89 04 24             	mov    %eax,(%esp)
f0100e0b:	ff d3                	call   *%ebx
f0100e0d:	eb 03                	jmp    f0100e12 <printnum+0xa2>
f0100e0f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e12:	83 ee 01             	sub    $0x1,%esi
f0100e15:	85 f6                	test   %esi,%esi
f0100e17:	7f e8                	jg     f0100e01 <printnum+0x91>
f0100e19:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e1c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e20:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e24:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e27:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e2a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e2e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e32:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e35:	89 04 24             	mov    %eax,(%esp)
f0100e38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e3f:	e8 8c 0a 00 00       	call   f01018d0 <__umoddi3>
f0100e44:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e48:	0f be 80 e9 1f 10 f0 	movsbl -0xfefe017(%eax),%eax
f0100e4f:	89 04 24             	mov    %eax,(%esp)
f0100e52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e55:	ff d0                	call   *%eax
}
f0100e57:	83 c4 3c             	add    $0x3c,%esp
f0100e5a:	5b                   	pop    %ebx
f0100e5b:	5e                   	pop    %esi
f0100e5c:	5f                   	pop    %edi
f0100e5d:	5d                   	pop    %ebp
f0100e5e:	c3                   	ret    

f0100e5f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e5f:	55                   	push   %ebp
f0100e60:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e62:	83 fa 01             	cmp    $0x1,%edx
f0100e65:	7e 0e                	jle    f0100e75 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e67:	8b 10                	mov    (%eax),%edx
f0100e69:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e6c:	89 08                	mov    %ecx,(%eax)
f0100e6e:	8b 02                	mov    (%edx),%eax
f0100e70:	8b 52 04             	mov    0x4(%edx),%edx
f0100e73:	eb 22                	jmp    f0100e97 <getuint+0x38>
	else if (lflag)
f0100e75:	85 d2                	test   %edx,%edx
f0100e77:	74 10                	je     f0100e89 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e79:	8b 10                	mov    (%eax),%edx
f0100e7b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e7e:	89 08                	mov    %ecx,(%eax)
f0100e80:	8b 02                	mov    (%edx),%eax
f0100e82:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e87:	eb 0e                	jmp    f0100e97 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e89:	8b 10                	mov    (%eax),%edx
f0100e8b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e8e:	89 08                	mov    %ecx,(%eax)
f0100e90:	8b 02                	mov    (%edx),%eax
f0100e92:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e97:	5d                   	pop    %ebp
f0100e98:	c3                   	ret    

f0100e99 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e99:	55                   	push   %ebp
f0100e9a:	89 e5                	mov    %esp,%ebp
f0100e9c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e9f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ea3:	8b 10                	mov    (%eax),%edx
f0100ea5:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ea8:	73 0a                	jae    f0100eb4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100eaa:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ead:	89 08                	mov    %ecx,(%eax)
f0100eaf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb2:	88 02                	mov    %al,(%edx)
}
f0100eb4:	5d                   	pop    %ebp
f0100eb5:	c3                   	ret    

f0100eb6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eb6:	55                   	push   %ebp
f0100eb7:	89 e5                	mov    %esp,%ebp
f0100eb9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ebc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ebf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ec3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ec6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100eca:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ecd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ed1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ed4:	89 04 24             	mov    %eax,(%esp)
f0100ed7:	e8 02 00 00 00       	call   f0100ede <vprintfmt>
	va_end(ap);
}
f0100edc:	c9                   	leave  
f0100edd:	c3                   	ret    

f0100ede <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ede:	55                   	push   %ebp
f0100edf:	89 e5                	mov    %esp,%ebp
f0100ee1:	57                   	push   %edi
f0100ee2:	56                   	push   %esi
f0100ee3:	53                   	push   %ebx
f0100ee4:	83 ec 3c             	sub    $0x3c,%esp
f0100ee7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100eea:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100eed:	eb 14                	jmp    f0100f03 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100eef:	85 c0                	test   %eax,%eax
f0100ef1:	0f 84 b3 03 00 00    	je     f01012aa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100ef7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100efb:	89 04 24             	mov    %eax,(%esp)
f0100efe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f01:	89 f3                	mov    %esi,%ebx
f0100f03:	8d 73 01             	lea    0x1(%ebx),%esi
f0100f06:	0f b6 03             	movzbl (%ebx),%eax
f0100f09:	83 f8 25             	cmp    $0x25,%eax
f0100f0c:	75 e1                	jne    f0100eef <vprintfmt+0x11>
f0100f0e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100f12:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100f19:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f20:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f27:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f2c:	eb 1d                	jmp    f0100f4b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f30:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f34:	eb 15                	jmp    f0100f4b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f36:	89 de                	mov    %ebx,%esi
			goto reswitch;


		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f38:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f3c:	eb 0d                	jmp    f0100f4b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f41:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f44:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f4e:	0f b6 0e             	movzbl (%esi),%ecx
f0100f51:	0f b6 c1             	movzbl %cl,%eax
f0100f54:	83 e9 23             	sub    $0x23,%ecx
f0100f57:	80 f9 55             	cmp    $0x55,%cl
f0100f5a:	0f 87 2a 03 00 00    	ja     f010128a <vprintfmt+0x3ac>
f0100f60:	0f b6 c9             	movzbl %cl,%ecx
f0100f63:	ff 24 8d 80 20 10 f0 	jmp    *-0xfefdf80(,%ecx,4)
f0100f6a:	89 de                	mov    %ebx,%esi
f0100f6c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f71:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f74:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f78:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f7b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f7e:	83 fb 09             	cmp    $0x9,%ebx
f0100f81:	77 36                	ja     f0100fb9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f83:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f86:	eb e9                	jmp    f0100f71 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f88:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f8e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f91:	8b 00                	mov    (%eax),%eax
f0100f93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f96:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f98:	eb 22                	jmp    f0100fbc <vprintfmt+0xde>
f0100f9a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f9d:	85 c9                	test   %ecx,%ecx
f0100f9f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fa4:	0f 49 c1             	cmovns %ecx,%eax
f0100fa7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100faa:	89 de                	mov    %ebx,%esi
f0100fac:	eb 9d                	jmp    f0100f4b <vprintfmt+0x6d>
f0100fae:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fb0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100fb7:	eb 92                	jmp    f0100f4b <vprintfmt+0x6d>
f0100fb9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100fbc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fc0:	79 89                	jns    f0100f4b <vprintfmt+0x6d>
f0100fc2:	e9 77 ff ff ff       	jmp    f0100f3e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fc7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fca:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fcc:	e9 7a ff ff ff       	jmp    f0100f4b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd4:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fda:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fde:	8b 00                	mov    (%eax),%eax
f0100fe0:	89 04 24             	mov    %eax,(%esp)
f0100fe3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fe6:	e9 18 ff ff ff       	jmp    f0100f03 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100feb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fee:	8d 50 04             	lea    0x4(%eax),%edx
f0100ff1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff4:	8b 00                	mov    (%eax),%eax
f0100ff6:	99                   	cltd   
f0100ff7:	31 d0                	xor    %edx,%eax
f0100ff9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ffb:	83 f8 07             	cmp    $0x7,%eax
f0100ffe:	7f 0b                	jg     f010100b <vprintfmt+0x12d>
f0101000:	8b 14 85 e0 21 10 f0 	mov    -0xfefde20(,%eax,4),%edx
f0101007:	85 d2                	test   %edx,%edx
f0101009:	75 20                	jne    f010102b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010100b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010100f:	c7 44 24 08 01 20 10 	movl   $0xf0102001,0x8(%esp)
f0101016:	f0 
f0101017:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010101b:	8b 45 08             	mov    0x8(%ebp),%eax
f010101e:	89 04 24             	mov    %eax,(%esp)
f0101021:	e8 90 fe ff ff       	call   f0100eb6 <printfmt>
f0101026:	e9 d8 fe ff ff       	jmp    f0100f03 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010102b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010102f:	c7 44 24 08 ec 1d 10 	movl   $0xf0101dec,0x8(%esp)
f0101036:	f0 
f0101037:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010103b:	8b 45 08             	mov    0x8(%ebp),%eax
f010103e:	89 04 24             	mov    %eax,(%esp)
f0101041:	e8 70 fe ff ff       	call   f0100eb6 <printfmt>
f0101046:	e9 b8 fe ff ff       	jmp    f0100f03 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010104b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010104e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101051:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101054:	8b 45 14             	mov    0x14(%ebp),%eax
f0101057:	8d 50 04             	lea    0x4(%eax),%edx
f010105a:	89 55 14             	mov    %edx,0x14(%ebp)
f010105d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010105f:	85 f6                	test   %esi,%esi
f0101061:	b8 fa 1f 10 f0       	mov    $0xf0101ffa,%eax
f0101066:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101069:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010106d:	0f 84 97 00 00 00    	je     f010110a <vprintfmt+0x22c>
f0101073:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101077:	0f 8e 9b 00 00 00    	jle    f0101118 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010107d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101081:	89 34 24             	mov    %esi,(%esp)
f0101084:	e8 9f 03 00 00       	call   f0101428 <strnlen>
f0101089:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010108c:	29 c2                	sub    %eax,%edx
f010108e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101091:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101095:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101098:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010109b:	8b 75 08             	mov    0x8(%ebp),%esi
f010109e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010a1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a3:	eb 0f                	jmp    f01010b4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01010a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010ac:	89 04 24             	mov    %eax,(%esp)
f01010af:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010b1:	83 eb 01             	sub    $0x1,%ebx
f01010b4:	85 db                	test   %ebx,%ebx
f01010b6:	7f ed                	jg     f01010a5 <vprintfmt+0x1c7>
f01010b8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01010bb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01010be:	85 d2                	test   %edx,%edx
f01010c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c5:	0f 49 c2             	cmovns %edx,%eax
f01010c8:	29 c2                	sub    %eax,%edx
f01010ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010cd:	89 d7                	mov    %edx,%edi
f01010cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010d2:	eb 50                	jmp    f0101124 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010d8:	74 1e                	je     f01010f8 <vprintfmt+0x21a>
f01010da:	0f be d2             	movsbl %dl,%edx
f01010dd:	83 ea 20             	sub    $0x20,%edx
f01010e0:	83 fa 5e             	cmp    $0x5e,%edx
f01010e3:	76 13                	jbe    f01010f8 <vprintfmt+0x21a>
					putch('?', putdat);
f01010e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010ec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010f3:	ff 55 08             	call   *0x8(%ebp)
f01010f6:	eb 0d                	jmp    f0101105 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01010f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010ff:	89 04 24             	mov    %eax,(%esp)
f0101102:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101105:	83 ef 01             	sub    $0x1,%edi
f0101108:	eb 1a                	jmp    f0101124 <vprintfmt+0x246>
f010110a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010110d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101110:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101113:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101116:	eb 0c                	jmp    f0101124 <vprintfmt+0x246>
f0101118:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010111b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010111e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101121:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101124:	83 c6 01             	add    $0x1,%esi
f0101127:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010112b:	0f be c2             	movsbl %dl,%eax
f010112e:	85 c0                	test   %eax,%eax
f0101130:	74 27                	je     f0101159 <vprintfmt+0x27b>
f0101132:	85 db                	test   %ebx,%ebx
f0101134:	78 9e                	js     f01010d4 <vprintfmt+0x1f6>
f0101136:	83 eb 01             	sub    $0x1,%ebx
f0101139:	79 99                	jns    f01010d4 <vprintfmt+0x1f6>
f010113b:	89 f8                	mov    %edi,%eax
f010113d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101140:	8b 75 08             	mov    0x8(%ebp),%esi
f0101143:	89 c3                	mov    %eax,%ebx
f0101145:	eb 1a                	jmp    f0101161 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101147:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010114b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101152:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101154:	83 eb 01             	sub    $0x1,%ebx
f0101157:	eb 08                	jmp    f0101161 <vprintfmt+0x283>
f0101159:	89 fb                	mov    %edi,%ebx
f010115b:	8b 75 08             	mov    0x8(%ebp),%esi
f010115e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101161:	85 db                	test   %ebx,%ebx
f0101163:	7f e2                	jg     f0101147 <vprintfmt+0x269>
f0101165:	89 75 08             	mov    %esi,0x8(%ebp)
f0101168:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010116b:	e9 93 fd ff ff       	jmp    f0100f03 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101170:	83 fa 01             	cmp    $0x1,%edx
f0101173:	7e 16                	jle    f010118b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101175:	8b 45 14             	mov    0x14(%ebp),%eax
f0101178:	8d 50 08             	lea    0x8(%eax),%edx
f010117b:	89 55 14             	mov    %edx,0x14(%ebp)
f010117e:	8b 50 04             	mov    0x4(%eax),%edx
f0101181:	8b 00                	mov    (%eax),%eax
f0101183:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101186:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101189:	eb 32                	jmp    f01011bd <vprintfmt+0x2df>
	else if (lflag)
f010118b:	85 d2                	test   %edx,%edx
f010118d:	74 18                	je     f01011a7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010118f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101192:	8d 50 04             	lea    0x4(%eax),%edx
f0101195:	89 55 14             	mov    %edx,0x14(%ebp)
f0101198:	8b 30                	mov    (%eax),%esi
f010119a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010119d:	89 f0                	mov    %esi,%eax
f010119f:	c1 f8 1f             	sar    $0x1f,%eax
f01011a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011a5:	eb 16                	jmp    f01011bd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01011a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011aa:	8d 50 04             	lea    0x4(%eax),%edx
f01011ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01011b0:	8b 30                	mov    (%eax),%esi
f01011b2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01011b5:	89 f0                	mov    %esi,%eax
f01011b7:	c1 f8 1f             	sar    $0x1f,%eax
f01011ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01011cc:	0f 89 80 00 00 00    	jns    f0101252 <vprintfmt+0x374>
				putch('-', putdat);
f01011d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011dd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011e6:	f7 d8                	neg    %eax
f01011e8:	83 d2 00             	adc    $0x0,%edx
f01011eb:	f7 da                	neg    %edx
			}
			base = 10;
f01011ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011f2:	eb 5e                	jmp    f0101252 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011f4:	8d 45 14             	lea    0x14(%ebp),%eax
f01011f7:	e8 63 fc ff ff       	call   f0100e5f <getuint>
			base = 10;
f01011fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101201:	eb 4f                	jmp    f0101252 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
f0101203:	8d 45 14             	lea    0x14(%ebp),%eax
f0101206:	e8 54 fc ff ff       	call   f0100e5f <getuint>
			base=8;
f010120b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101210:	eb 40                	jmp    f0101252 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0101212:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101216:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010121d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101220:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101224:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010122b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010122e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101231:	8d 50 04             	lea    0x4(%eax),%edx
f0101234:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101237:	8b 00                	mov    (%eax),%eax
f0101239:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010123e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101243:	eb 0d                	jmp    f0101252 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101245:	8d 45 14             	lea    0x14(%ebp),%eax
f0101248:	e8 12 fc ff ff       	call   f0100e5f <getuint>
			base = 16;
f010124d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101252:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101256:	89 74 24 10          	mov    %esi,0x10(%esp)
f010125a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010125d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101261:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101265:	89 04 24             	mov    %eax,(%esp)
f0101268:	89 54 24 04          	mov    %edx,0x4(%esp)
f010126c:	89 fa                	mov    %edi,%edx
f010126e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101271:	e8 fa fa ff ff       	call   f0100d70 <printnum>
			break;
f0101276:	e9 88 fc ff ff       	jmp    f0100f03 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010127b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010127f:	89 04 24             	mov    %eax,(%esp)
f0101282:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101285:	e9 79 fc ff ff       	jmp    f0100f03 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010128a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010128e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101295:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101298:	89 f3                	mov    %esi,%ebx
f010129a:	eb 03                	jmp    f010129f <vprintfmt+0x3c1>
f010129c:	83 eb 01             	sub    $0x1,%ebx
f010129f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01012a3:	75 f7                	jne    f010129c <vprintfmt+0x3be>
f01012a5:	e9 59 fc ff ff       	jmp    f0100f03 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01012aa:	83 c4 3c             	add    $0x3c,%esp
f01012ad:	5b                   	pop    %ebx
f01012ae:	5e                   	pop    %esi
f01012af:	5f                   	pop    %edi
f01012b0:	5d                   	pop    %ebp
f01012b1:	c3                   	ret    

f01012b2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012b2:	55                   	push   %ebp
f01012b3:	89 e5                	mov    %esp,%ebp
f01012b5:	83 ec 28             	sub    $0x28,%esp
f01012b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012c1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012c5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012cf:	85 c0                	test   %eax,%eax
f01012d1:	74 30                	je     f0101303 <vsnprintf+0x51>
f01012d3:	85 d2                	test   %edx,%edx
f01012d5:	7e 2c                	jle    f0101303 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012de:	8b 45 10             	mov    0x10(%ebp),%eax
f01012e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012ec:	c7 04 24 99 0e 10 f0 	movl   $0xf0100e99,(%esp)
f01012f3:	e8 e6 fb ff ff       	call   f0100ede <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012fb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101301:	eb 05                	jmp    f0101308 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101303:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101308:	c9                   	leave  
f0101309:	c3                   	ret    

f010130a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010130a:	55                   	push   %ebp
f010130b:	89 e5                	mov    %esp,%ebp
f010130d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101310:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101313:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101317:	8b 45 10             	mov    0x10(%ebp),%eax
f010131a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010131e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101321:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101325:	8b 45 08             	mov    0x8(%ebp),%eax
f0101328:	89 04 24             	mov    %eax,(%esp)
f010132b:	e8 82 ff ff ff       	call   f01012b2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101330:	c9                   	leave  
f0101331:	c3                   	ret    
f0101332:	66 90                	xchg   %ax,%ax
f0101334:	66 90                	xchg   %ax,%ax
f0101336:	66 90                	xchg   %ax,%ax
f0101338:	66 90                	xchg   %ax,%ax
f010133a:	66 90                	xchg   %ax,%ax
f010133c:	66 90                	xchg   %ax,%ax
f010133e:	66 90                	xchg   %ax,%ax

f0101340 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101340:	55                   	push   %ebp
f0101341:	89 e5                	mov    %esp,%ebp
f0101343:	57                   	push   %edi
f0101344:	56                   	push   %esi
f0101345:	53                   	push   %ebx
f0101346:	83 ec 1c             	sub    $0x1c,%esp
f0101349:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010134c:	85 c0                	test   %eax,%eax
f010134e:	74 10                	je     f0101360 <readline+0x20>
		cprintf("%s", prompt);
f0101350:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101354:	c7 04 24 ec 1d 10 f0 	movl   $0xf0101dec,(%esp)
f010135b:	e8 d1 f6 ff ff       	call   f0100a31 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101360:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101367:	e8 06 f3 ff ff       	call   f0100672 <iscons>
f010136c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010136e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101373:	e8 e9 f2 ff ff       	call   f0100661 <getchar>
f0101378:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010137a:	85 c0                	test   %eax,%eax
f010137c:	79 17                	jns    f0101395 <readline+0x55>
			cprintf("read error: %e\n", c);
f010137e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101382:	c7 04 24 00 22 10 f0 	movl   $0xf0102200,(%esp)
f0101389:	e8 a3 f6 ff ff       	call   f0100a31 <cprintf>
			return NULL;
f010138e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101393:	eb 6d                	jmp    f0101402 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101395:	83 f8 7f             	cmp    $0x7f,%eax
f0101398:	74 05                	je     f010139f <readline+0x5f>
f010139a:	83 f8 08             	cmp    $0x8,%eax
f010139d:	75 19                	jne    f01013b8 <readline+0x78>
f010139f:	85 f6                	test   %esi,%esi
f01013a1:	7e 15                	jle    f01013b8 <readline+0x78>
			if (echoing)
f01013a3:	85 ff                	test   %edi,%edi
f01013a5:	74 0c                	je     f01013b3 <readline+0x73>
				cputchar('\b');
f01013a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013ae:	e8 9e f2 ff ff       	call   f0100651 <cputchar>
			i--;
f01013b3:	83 ee 01             	sub    $0x1,%esi
f01013b6:	eb bb                	jmp    f0101373 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013be:	7f 1c                	jg     f01013dc <readline+0x9c>
f01013c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013c3:	7e 17                	jle    f01013dc <readline+0x9c>
			if (echoing)
f01013c5:	85 ff                	test   %edi,%edi
f01013c7:	74 08                	je     f01013d1 <readline+0x91>
				cputchar(c);
f01013c9:	89 1c 24             	mov    %ebx,(%esp)
f01013cc:	e8 80 f2 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f01013d1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01013d7:	8d 76 01             	lea    0x1(%esi),%esi
f01013da:	eb 97                	jmp    f0101373 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013dc:	83 fb 0d             	cmp    $0xd,%ebx
f01013df:	74 05                	je     f01013e6 <readline+0xa6>
f01013e1:	83 fb 0a             	cmp    $0xa,%ebx
f01013e4:	75 8d                	jne    f0101373 <readline+0x33>
			if (echoing)
f01013e6:	85 ff                	test   %edi,%edi
f01013e8:	74 0c                	je     f01013f6 <readline+0xb6>
				cputchar('\n');
f01013ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013f1:	e8 5b f2 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f01013f6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013fd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101402:	83 c4 1c             	add    $0x1c,%esp
f0101405:	5b                   	pop    %ebx
f0101406:	5e                   	pop    %esi
f0101407:	5f                   	pop    %edi
f0101408:	5d                   	pop    %ebp
f0101409:	c3                   	ret    
f010140a:	66 90                	xchg   %ax,%ax
f010140c:	66 90                	xchg   %ax,%ax
f010140e:	66 90                	xchg   %ax,%ax

f0101410 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101410:	55                   	push   %ebp
f0101411:	89 e5                	mov    %esp,%ebp
f0101413:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101416:	b8 00 00 00 00       	mov    $0x0,%eax
f010141b:	eb 03                	jmp    f0101420 <strlen+0x10>
		n++;
f010141d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101420:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101424:	75 f7                	jne    f010141d <strlen+0xd>
		n++;
	return n;
}
f0101426:	5d                   	pop    %ebp
f0101427:	c3                   	ret    

f0101428 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101428:	55                   	push   %ebp
f0101429:	89 e5                	mov    %esp,%ebp
f010142b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010142e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101431:	b8 00 00 00 00       	mov    $0x0,%eax
f0101436:	eb 03                	jmp    f010143b <strnlen+0x13>
		n++;
f0101438:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010143b:	39 d0                	cmp    %edx,%eax
f010143d:	74 06                	je     f0101445 <strnlen+0x1d>
f010143f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101443:	75 f3                	jne    f0101438 <strnlen+0x10>
		n++;
	return n;
}
f0101445:	5d                   	pop    %ebp
f0101446:	c3                   	ret    

f0101447 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101447:	55                   	push   %ebp
f0101448:	89 e5                	mov    %esp,%ebp
f010144a:	53                   	push   %ebx
f010144b:	8b 45 08             	mov    0x8(%ebp),%eax
f010144e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101451:	89 c2                	mov    %eax,%edx
f0101453:	83 c2 01             	add    $0x1,%edx
f0101456:	83 c1 01             	add    $0x1,%ecx
f0101459:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010145d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101460:	84 db                	test   %bl,%bl
f0101462:	75 ef                	jne    f0101453 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101464:	5b                   	pop    %ebx
f0101465:	5d                   	pop    %ebp
f0101466:	c3                   	ret    

f0101467 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101467:	55                   	push   %ebp
f0101468:	89 e5                	mov    %esp,%ebp
f010146a:	53                   	push   %ebx
f010146b:	83 ec 08             	sub    $0x8,%esp
f010146e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101471:	89 1c 24             	mov    %ebx,(%esp)
f0101474:	e8 97 ff ff ff       	call   f0101410 <strlen>
	strcpy(dst + len, src);
f0101479:	8b 55 0c             	mov    0xc(%ebp),%edx
f010147c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101480:	01 d8                	add    %ebx,%eax
f0101482:	89 04 24             	mov    %eax,(%esp)
f0101485:	e8 bd ff ff ff       	call   f0101447 <strcpy>
	return dst;
}
f010148a:	89 d8                	mov    %ebx,%eax
f010148c:	83 c4 08             	add    $0x8,%esp
f010148f:	5b                   	pop    %ebx
f0101490:	5d                   	pop    %ebp
f0101491:	c3                   	ret    

f0101492 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101492:	55                   	push   %ebp
f0101493:	89 e5                	mov    %esp,%ebp
f0101495:	56                   	push   %esi
f0101496:	53                   	push   %ebx
f0101497:	8b 75 08             	mov    0x8(%ebp),%esi
f010149a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010149d:	89 f3                	mov    %esi,%ebx
f010149f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014a2:	89 f2                	mov    %esi,%edx
f01014a4:	eb 0f                	jmp    f01014b5 <strncpy+0x23>
		*dst++ = *src;
f01014a6:	83 c2 01             	add    $0x1,%edx
f01014a9:	0f b6 01             	movzbl (%ecx),%eax
f01014ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014af:	80 39 01             	cmpb   $0x1,(%ecx)
f01014b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014b5:	39 da                	cmp    %ebx,%edx
f01014b7:	75 ed                	jne    f01014a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014b9:	89 f0                	mov    %esi,%eax
f01014bb:	5b                   	pop    %ebx
f01014bc:	5e                   	pop    %esi
f01014bd:	5d                   	pop    %ebp
f01014be:	c3                   	ret    

f01014bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014bf:	55                   	push   %ebp
f01014c0:	89 e5                	mov    %esp,%ebp
f01014c2:	56                   	push   %esi
f01014c3:	53                   	push   %ebx
f01014c4:	8b 75 08             	mov    0x8(%ebp),%esi
f01014c7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01014cd:	89 f0                	mov    %esi,%eax
f01014cf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014d3:	85 c9                	test   %ecx,%ecx
f01014d5:	75 0b                	jne    f01014e2 <strlcpy+0x23>
f01014d7:	eb 1d                	jmp    f01014f6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014d9:	83 c0 01             	add    $0x1,%eax
f01014dc:	83 c2 01             	add    $0x1,%edx
f01014df:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014e2:	39 d8                	cmp    %ebx,%eax
f01014e4:	74 0b                	je     f01014f1 <strlcpy+0x32>
f01014e6:	0f b6 0a             	movzbl (%edx),%ecx
f01014e9:	84 c9                	test   %cl,%cl
f01014eb:	75 ec                	jne    f01014d9 <strlcpy+0x1a>
f01014ed:	89 c2                	mov    %eax,%edx
f01014ef:	eb 02                	jmp    f01014f3 <strlcpy+0x34>
f01014f1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01014f3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014f6:	29 f0                	sub    %esi,%eax
}
f01014f8:	5b                   	pop    %ebx
f01014f9:	5e                   	pop    %esi
f01014fa:	5d                   	pop    %ebp
f01014fb:	c3                   	ret    

f01014fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014fc:	55                   	push   %ebp
f01014fd:	89 e5                	mov    %esp,%ebp
f01014ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101502:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101505:	eb 06                	jmp    f010150d <strcmp+0x11>
		p++, q++;
f0101507:	83 c1 01             	add    $0x1,%ecx
f010150a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010150d:	0f b6 01             	movzbl (%ecx),%eax
f0101510:	84 c0                	test   %al,%al
f0101512:	74 04                	je     f0101518 <strcmp+0x1c>
f0101514:	3a 02                	cmp    (%edx),%al
f0101516:	74 ef                	je     f0101507 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101518:	0f b6 c0             	movzbl %al,%eax
f010151b:	0f b6 12             	movzbl (%edx),%edx
f010151e:	29 d0                	sub    %edx,%eax
}
f0101520:	5d                   	pop    %ebp
f0101521:	c3                   	ret    

f0101522 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101522:	55                   	push   %ebp
f0101523:	89 e5                	mov    %esp,%ebp
f0101525:	53                   	push   %ebx
f0101526:	8b 45 08             	mov    0x8(%ebp),%eax
f0101529:	8b 55 0c             	mov    0xc(%ebp),%edx
f010152c:	89 c3                	mov    %eax,%ebx
f010152e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101531:	eb 06                	jmp    f0101539 <strncmp+0x17>
		n--, p++, q++;
f0101533:	83 c0 01             	add    $0x1,%eax
f0101536:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101539:	39 d8                	cmp    %ebx,%eax
f010153b:	74 15                	je     f0101552 <strncmp+0x30>
f010153d:	0f b6 08             	movzbl (%eax),%ecx
f0101540:	84 c9                	test   %cl,%cl
f0101542:	74 04                	je     f0101548 <strncmp+0x26>
f0101544:	3a 0a                	cmp    (%edx),%cl
f0101546:	74 eb                	je     f0101533 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101548:	0f b6 00             	movzbl (%eax),%eax
f010154b:	0f b6 12             	movzbl (%edx),%edx
f010154e:	29 d0                	sub    %edx,%eax
f0101550:	eb 05                	jmp    f0101557 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101552:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101557:	5b                   	pop    %ebx
f0101558:	5d                   	pop    %ebp
f0101559:	c3                   	ret    

f010155a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010155a:	55                   	push   %ebp
f010155b:	89 e5                	mov    %esp,%ebp
f010155d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101560:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101564:	eb 07                	jmp    f010156d <strchr+0x13>
		if (*s == c)
f0101566:	38 ca                	cmp    %cl,%dl
f0101568:	74 0f                	je     f0101579 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010156a:	83 c0 01             	add    $0x1,%eax
f010156d:	0f b6 10             	movzbl (%eax),%edx
f0101570:	84 d2                	test   %dl,%dl
f0101572:	75 f2                	jne    f0101566 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101574:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101579:	5d                   	pop    %ebp
f010157a:	c3                   	ret    

f010157b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010157b:	55                   	push   %ebp
f010157c:	89 e5                	mov    %esp,%ebp
f010157e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101581:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101585:	eb 07                	jmp    f010158e <strfind+0x13>
		if (*s == c)
f0101587:	38 ca                	cmp    %cl,%dl
f0101589:	74 0a                	je     f0101595 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010158b:	83 c0 01             	add    $0x1,%eax
f010158e:	0f b6 10             	movzbl (%eax),%edx
f0101591:	84 d2                	test   %dl,%dl
f0101593:	75 f2                	jne    f0101587 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101595:	5d                   	pop    %ebp
f0101596:	c3                   	ret    

f0101597 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101597:	55                   	push   %ebp
f0101598:	89 e5                	mov    %esp,%ebp
f010159a:	57                   	push   %edi
f010159b:	56                   	push   %esi
f010159c:	53                   	push   %ebx
f010159d:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015a3:	85 c9                	test   %ecx,%ecx
f01015a5:	74 36                	je     f01015dd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015a7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015ad:	75 28                	jne    f01015d7 <memset+0x40>
f01015af:	f6 c1 03             	test   $0x3,%cl
f01015b2:	75 23                	jne    f01015d7 <memset+0x40>
		c &= 0xFF;
f01015b4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015b8:	89 d3                	mov    %edx,%ebx
f01015ba:	c1 e3 08             	shl    $0x8,%ebx
f01015bd:	89 d6                	mov    %edx,%esi
f01015bf:	c1 e6 18             	shl    $0x18,%esi
f01015c2:	89 d0                	mov    %edx,%eax
f01015c4:	c1 e0 10             	shl    $0x10,%eax
f01015c7:	09 f0                	or     %esi,%eax
f01015c9:	09 c2                	or     %eax,%edx
f01015cb:	89 d0                	mov    %edx,%eax
f01015cd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015cf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015d2:	fc                   	cld    
f01015d3:	f3 ab                	rep stos %eax,%es:(%edi)
f01015d5:	eb 06                	jmp    f01015dd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015da:	fc                   	cld    
f01015db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015dd:	89 f8                	mov    %edi,%eax
f01015df:	5b                   	pop    %ebx
f01015e0:	5e                   	pop    %esi
f01015e1:	5f                   	pop    %edi
f01015e2:	5d                   	pop    %ebp
f01015e3:	c3                   	ret    

f01015e4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015e4:	55                   	push   %ebp
f01015e5:	89 e5                	mov    %esp,%ebp
f01015e7:	57                   	push   %edi
f01015e8:	56                   	push   %esi
f01015e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015f2:	39 c6                	cmp    %eax,%esi
f01015f4:	73 35                	jae    f010162b <memmove+0x47>
f01015f6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015f9:	39 d0                	cmp    %edx,%eax
f01015fb:	73 2e                	jae    f010162b <memmove+0x47>
		s += n;
		d += n;
f01015fd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101600:	89 d6                	mov    %edx,%esi
f0101602:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101604:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010160a:	75 13                	jne    f010161f <memmove+0x3b>
f010160c:	f6 c1 03             	test   $0x3,%cl
f010160f:	75 0e                	jne    f010161f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101611:	83 ef 04             	sub    $0x4,%edi
f0101614:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101617:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010161a:	fd                   	std    
f010161b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010161d:	eb 09                	jmp    f0101628 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010161f:	83 ef 01             	sub    $0x1,%edi
f0101622:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101625:	fd                   	std    
f0101626:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101628:	fc                   	cld    
f0101629:	eb 1d                	jmp    f0101648 <memmove+0x64>
f010162b:	89 f2                	mov    %esi,%edx
f010162d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010162f:	f6 c2 03             	test   $0x3,%dl
f0101632:	75 0f                	jne    f0101643 <memmove+0x5f>
f0101634:	f6 c1 03             	test   $0x3,%cl
f0101637:	75 0a                	jne    f0101643 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101639:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010163c:	89 c7                	mov    %eax,%edi
f010163e:	fc                   	cld    
f010163f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101641:	eb 05                	jmp    f0101648 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101643:	89 c7                	mov    %eax,%edi
f0101645:	fc                   	cld    
f0101646:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101648:	5e                   	pop    %esi
f0101649:	5f                   	pop    %edi
f010164a:	5d                   	pop    %ebp
f010164b:	c3                   	ret    

f010164c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010164c:	55                   	push   %ebp
f010164d:	89 e5                	mov    %esp,%ebp
f010164f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101652:	8b 45 10             	mov    0x10(%ebp),%eax
f0101655:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101659:	8b 45 0c             	mov    0xc(%ebp),%eax
f010165c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101660:	8b 45 08             	mov    0x8(%ebp),%eax
f0101663:	89 04 24             	mov    %eax,(%esp)
f0101666:	e8 79 ff ff ff       	call   f01015e4 <memmove>
}
f010166b:	c9                   	leave  
f010166c:	c3                   	ret    

f010166d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010166d:	55                   	push   %ebp
f010166e:	89 e5                	mov    %esp,%ebp
f0101670:	56                   	push   %esi
f0101671:	53                   	push   %ebx
f0101672:	8b 55 08             	mov    0x8(%ebp),%edx
f0101675:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101678:	89 d6                	mov    %edx,%esi
f010167a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010167d:	eb 1a                	jmp    f0101699 <memcmp+0x2c>
		if (*s1 != *s2)
f010167f:	0f b6 02             	movzbl (%edx),%eax
f0101682:	0f b6 19             	movzbl (%ecx),%ebx
f0101685:	38 d8                	cmp    %bl,%al
f0101687:	74 0a                	je     f0101693 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101689:	0f b6 c0             	movzbl %al,%eax
f010168c:	0f b6 db             	movzbl %bl,%ebx
f010168f:	29 d8                	sub    %ebx,%eax
f0101691:	eb 0f                	jmp    f01016a2 <memcmp+0x35>
		s1++, s2++;
f0101693:	83 c2 01             	add    $0x1,%edx
f0101696:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101699:	39 f2                	cmp    %esi,%edx
f010169b:	75 e2                	jne    f010167f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010169d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016a2:	5b                   	pop    %ebx
f01016a3:	5e                   	pop    %esi
f01016a4:	5d                   	pop    %ebp
f01016a5:	c3                   	ret    

f01016a6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016a6:	55                   	push   %ebp
f01016a7:	89 e5                	mov    %esp,%ebp
f01016a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016af:	89 c2                	mov    %eax,%edx
f01016b1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016b4:	eb 07                	jmp    f01016bd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016b6:	38 08                	cmp    %cl,(%eax)
f01016b8:	74 07                	je     f01016c1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016ba:	83 c0 01             	add    $0x1,%eax
f01016bd:	39 d0                	cmp    %edx,%eax
f01016bf:	72 f5                	jb     f01016b6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016c1:	5d                   	pop    %ebp
f01016c2:	c3                   	ret    

f01016c3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016c3:	55                   	push   %ebp
f01016c4:	89 e5                	mov    %esp,%ebp
f01016c6:	57                   	push   %edi
f01016c7:	56                   	push   %esi
f01016c8:	53                   	push   %ebx
f01016c9:	8b 55 08             	mov    0x8(%ebp),%edx
f01016cc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016cf:	eb 03                	jmp    f01016d4 <strtol+0x11>
		s++;
f01016d1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016d4:	0f b6 0a             	movzbl (%edx),%ecx
f01016d7:	80 f9 09             	cmp    $0x9,%cl
f01016da:	74 f5                	je     f01016d1 <strtol+0xe>
f01016dc:	80 f9 20             	cmp    $0x20,%cl
f01016df:	74 f0                	je     f01016d1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016e1:	80 f9 2b             	cmp    $0x2b,%cl
f01016e4:	75 0a                	jne    f01016f0 <strtol+0x2d>
		s++;
f01016e6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016e9:	bf 00 00 00 00       	mov    $0x0,%edi
f01016ee:	eb 11                	jmp    f0101701 <strtol+0x3e>
f01016f0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016f5:	80 f9 2d             	cmp    $0x2d,%cl
f01016f8:	75 07                	jne    f0101701 <strtol+0x3e>
		s++, neg = 1;
f01016fa:	8d 52 01             	lea    0x1(%edx),%edx
f01016fd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101701:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101706:	75 15                	jne    f010171d <strtol+0x5a>
f0101708:	80 3a 30             	cmpb   $0x30,(%edx)
f010170b:	75 10                	jne    f010171d <strtol+0x5a>
f010170d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101711:	75 0a                	jne    f010171d <strtol+0x5a>
		s += 2, base = 16;
f0101713:	83 c2 02             	add    $0x2,%edx
f0101716:	b8 10 00 00 00       	mov    $0x10,%eax
f010171b:	eb 10                	jmp    f010172d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010171d:	85 c0                	test   %eax,%eax
f010171f:	75 0c                	jne    f010172d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101721:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101723:	80 3a 30             	cmpb   $0x30,(%edx)
f0101726:	75 05                	jne    f010172d <strtol+0x6a>
		s++, base = 8;
f0101728:	83 c2 01             	add    $0x1,%edx
f010172b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010172d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101732:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101735:	0f b6 0a             	movzbl (%edx),%ecx
f0101738:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010173b:	89 f0                	mov    %esi,%eax
f010173d:	3c 09                	cmp    $0x9,%al
f010173f:	77 08                	ja     f0101749 <strtol+0x86>
			dig = *s - '0';
f0101741:	0f be c9             	movsbl %cl,%ecx
f0101744:	83 e9 30             	sub    $0x30,%ecx
f0101747:	eb 20                	jmp    f0101769 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101749:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010174c:	89 f0                	mov    %esi,%eax
f010174e:	3c 19                	cmp    $0x19,%al
f0101750:	77 08                	ja     f010175a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101752:	0f be c9             	movsbl %cl,%ecx
f0101755:	83 e9 57             	sub    $0x57,%ecx
f0101758:	eb 0f                	jmp    f0101769 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010175a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010175d:	89 f0                	mov    %esi,%eax
f010175f:	3c 19                	cmp    $0x19,%al
f0101761:	77 16                	ja     f0101779 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101763:	0f be c9             	movsbl %cl,%ecx
f0101766:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101769:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010176c:	7d 0f                	jge    f010177d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010176e:	83 c2 01             	add    $0x1,%edx
f0101771:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101775:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101777:	eb bc                	jmp    f0101735 <strtol+0x72>
f0101779:	89 d8                	mov    %ebx,%eax
f010177b:	eb 02                	jmp    f010177f <strtol+0xbc>
f010177d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010177f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101783:	74 05                	je     f010178a <strtol+0xc7>
		*endptr = (char *) s;
f0101785:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101788:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010178a:	f7 d8                	neg    %eax
f010178c:	85 ff                	test   %edi,%edi
f010178e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101791:	5b                   	pop    %ebx
f0101792:	5e                   	pop    %esi
f0101793:	5f                   	pop    %edi
f0101794:	5d                   	pop    %ebp
f0101795:	c3                   	ret    
f0101796:	66 90                	xchg   %ax,%ax
f0101798:	66 90                	xchg   %ax,%ax
f010179a:	66 90                	xchg   %ax,%ax
f010179c:	66 90                	xchg   %ax,%ax
f010179e:	66 90                	xchg   %ax,%ax

f01017a0 <__udivdi3>:
f01017a0:	55                   	push   %ebp
f01017a1:	57                   	push   %edi
f01017a2:	56                   	push   %esi
f01017a3:	83 ec 0c             	sub    $0xc,%esp
f01017a6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017aa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017ae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017b2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017b6:	85 c0                	test   %eax,%eax
f01017b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017bc:	89 ea                	mov    %ebp,%edx
f01017be:	89 0c 24             	mov    %ecx,(%esp)
f01017c1:	75 2d                	jne    f01017f0 <__udivdi3+0x50>
f01017c3:	39 e9                	cmp    %ebp,%ecx
f01017c5:	77 61                	ja     f0101828 <__udivdi3+0x88>
f01017c7:	85 c9                	test   %ecx,%ecx
f01017c9:	89 ce                	mov    %ecx,%esi
f01017cb:	75 0b                	jne    f01017d8 <__udivdi3+0x38>
f01017cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01017d2:	31 d2                	xor    %edx,%edx
f01017d4:	f7 f1                	div    %ecx
f01017d6:	89 c6                	mov    %eax,%esi
f01017d8:	31 d2                	xor    %edx,%edx
f01017da:	89 e8                	mov    %ebp,%eax
f01017dc:	f7 f6                	div    %esi
f01017de:	89 c5                	mov    %eax,%ebp
f01017e0:	89 f8                	mov    %edi,%eax
f01017e2:	f7 f6                	div    %esi
f01017e4:	89 ea                	mov    %ebp,%edx
f01017e6:	83 c4 0c             	add    $0xc,%esp
f01017e9:	5e                   	pop    %esi
f01017ea:	5f                   	pop    %edi
f01017eb:	5d                   	pop    %ebp
f01017ec:	c3                   	ret    
f01017ed:	8d 76 00             	lea    0x0(%esi),%esi
f01017f0:	39 e8                	cmp    %ebp,%eax
f01017f2:	77 24                	ja     f0101818 <__udivdi3+0x78>
f01017f4:	0f bd e8             	bsr    %eax,%ebp
f01017f7:	83 f5 1f             	xor    $0x1f,%ebp
f01017fa:	75 3c                	jne    f0101838 <__udivdi3+0x98>
f01017fc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101800:	39 34 24             	cmp    %esi,(%esp)
f0101803:	0f 86 9f 00 00 00    	jbe    f01018a8 <__udivdi3+0x108>
f0101809:	39 d0                	cmp    %edx,%eax
f010180b:	0f 82 97 00 00 00    	jb     f01018a8 <__udivdi3+0x108>
f0101811:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101818:	31 d2                	xor    %edx,%edx
f010181a:	31 c0                	xor    %eax,%eax
f010181c:	83 c4 0c             	add    $0xc,%esp
f010181f:	5e                   	pop    %esi
f0101820:	5f                   	pop    %edi
f0101821:	5d                   	pop    %ebp
f0101822:	c3                   	ret    
f0101823:	90                   	nop
f0101824:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101828:	89 f8                	mov    %edi,%eax
f010182a:	f7 f1                	div    %ecx
f010182c:	31 d2                	xor    %edx,%edx
f010182e:	83 c4 0c             	add    $0xc,%esp
f0101831:	5e                   	pop    %esi
f0101832:	5f                   	pop    %edi
f0101833:	5d                   	pop    %ebp
f0101834:	c3                   	ret    
f0101835:	8d 76 00             	lea    0x0(%esi),%esi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	8b 3c 24             	mov    (%esp),%edi
f010183d:	d3 e0                	shl    %cl,%eax
f010183f:	89 c6                	mov    %eax,%esi
f0101841:	b8 20 00 00 00       	mov    $0x20,%eax
f0101846:	29 e8                	sub    %ebp,%eax
f0101848:	89 c1                	mov    %eax,%ecx
f010184a:	d3 ef                	shr    %cl,%edi
f010184c:	89 e9                	mov    %ebp,%ecx
f010184e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101852:	8b 3c 24             	mov    (%esp),%edi
f0101855:	09 74 24 08          	or     %esi,0x8(%esp)
f0101859:	89 d6                	mov    %edx,%esi
f010185b:	d3 e7                	shl    %cl,%edi
f010185d:	89 c1                	mov    %eax,%ecx
f010185f:	89 3c 24             	mov    %edi,(%esp)
f0101862:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101866:	d3 ee                	shr    %cl,%esi
f0101868:	89 e9                	mov    %ebp,%ecx
f010186a:	d3 e2                	shl    %cl,%edx
f010186c:	89 c1                	mov    %eax,%ecx
f010186e:	d3 ef                	shr    %cl,%edi
f0101870:	09 d7                	or     %edx,%edi
f0101872:	89 f2                	mov    %esi,%edx
f0101874:	89 f8                	mov    %edi,%eax
f0101876:	f7 74 24 08          	divl   0x8(%esp)
f010187a:	89 d6                	mov    %edx,%esi
f010187c:	89 c7                	mov    %eax,%edi
f010187e:	f7 24 24             	mull   (%esp)
f0101881:	39 d6                	cmp    %edx,%esi
f0101883:	89 14 24             	mov    %edx,(%esp)
f0101886:	72 30                	jb     f01018b8 <__udivdi3+0x118>
f0101888:	8b 54 24 04          	mov    0x4(%esp),%edx
f010188c:	89 e9                	mov    %ebp,%ecx
f010188e:	d3 e2                	shl    %cl,%edx
f0101890:	39 c2                	cmp    %eax,%edx
f0101892:	73 05                	jae    f0101899 <__udivdi3+0xf9>
f0101894:	3b 34 24             	cmp    (%esp),%esi
f0101897:	74 1f                	je     f01018b8 <__udivdi3+0x118>
f0101899:	89 f8                	mov    %edi,%eax
f010189b:	31 d2                	xor    %edx,%edx
f010189d:	e9 7a ff ff ff       	jmp    f010181c <__udivdi3+0x7c>
f01018a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018a8:	31 d2                	xor    %edx,%edx
f01018aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01018af:	e9 68 ff ff ff       	jmp    f010181c <__udivdi3+0x7c>
f01018b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018b8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018bb:	31 d2                	xor    %edx,%edx
f01018bd:	83 c4 0c             	add    $0xc,%esp
f01018c0:	5e                   	pop    %esi
f01018c1:	5f                   	pop    %edi
f01018c2:	5d                   	pop    %ebp
f01018c3:	c3                   	ret    
f01018c4:	66 90                	xchg   %ax,%ax
f01018c6:	66 90                	xchg   %ax,%ax
f01018c8:	66 90                	xchg   %ax,%ax
f01018ca:	66 90                	xchg   %ax,%ax
f01018cc:	66 90                	xchg   %ax,%ax
f01018ce:	66 90                	xchg   %ax,%ax

f01018d0 <__umoddi3>:
f01018d0:	55                   	push   %ebp
f01018d1:	57                   	push   %edi
f01018d2:	56                   	push   %esi
f01018d3:	83 ec 14             	sub    $0x14,%esp
f01018d6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018da:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018de:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018e2:	89 c7                	mov    %eax,%edi
f01018e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018e8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018ec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018f0:	89 34 24             	mov    %esi,(%esp)
f01018f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018f7:	85 c0                	test   %eax,%eax
f01018f9:	89 c2                	mov    %eax,%edx
f01018fb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018ff:	75 17                	jne    f0101918 <__umoddi3+0x48>
f0101901:	39 fe                	cmp    %edi,%esi
f0101903:	76 4b                	jbe    f0101950 <__umoddi3+0x80>
f0101905:	89 c8                	mov    %ecx,%eax
f0101907:	89 fa                	mov    %edi,%edx
f0101909:	f7 f6                	div    %esi
f010190b:	89 d0                	mov    %edx,%eax
f010190d:	31 d2                	xor    %edx,%edx
f010190f:	83 c4 14             	add    $0x14,%esp
f0101912:	5e                   	pop    %esi
f0101913:	5f                   	pop    %edi
f0101914:	5d                   	pop    %ebp
f0101915:	c3                   	ret    
f0101916:	66 90                	xchg   %ax,%ax
f0101918:	39 f8                	cmp    %edi,%eax
f010191a:	77 54                	ja     f0101970 <__umoddi3+0xa0>
f010191c:	0f bd e8             	bsr    %eax,%ebp
f010191f:	83 f5 1f             	xor    $0x1f,%ebp
f0101922:	75 5c                	jne    f0101980 <__umoddi3+0xb0>
f0101924:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101928:	39 3c 24             	cmp    %edi,(%esp)
f010192b:	0f 87 e7 00 00 00    	ja     f0101a18 <__umoddi3+0x148>
f0101931:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101935:	29 f1                	sub    %esi,%ecx
f0101937:	19 c7                	sbb    %eax,%edi
f0101939:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010193d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101941:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101945:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101949:	83 c4 14             	add    $0x14,%esp
f010194c:	5e                   	pop    %esi
f010194d:	5f                   	pop    %edi
f010194e:	5d                   	pop    %ebp
f010194f:	c3                   	ret    
f0101950:	85 f6                	test   %esi,%esi
f0101952:	89 f5                	mov    %esi,%ebp
f0101954:	75 0b                	jne    f0101961 <__umoddi3+0x91>
f0101956:	b8 01 00 00 00       	mov    $0x1,%eax
f010195b:	31 d2                	xor    %edx,%edx
f010195d:	f7 f6                	div    %esi
f010195f:	89 c5                	mov    %eax,%ebp
f0101961:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101965:	31 d2                	xor    %edx,%edx
f0101967:	f7 f5                	div    %ebp
f0101969:	89 c8                	mov    %ecx,%eax
f010196b:	f7 f5                	div    %ebp
f010196d:	eb 9c                	jmp    f010190b <__umoddi3+0x3b>
f010196f:	90                   	nop
f0101970:	89 c8                	mov    %ecx,%eax
f0101972:	89 fa                	mov    %edi,%edx
f0101974:	83 c4 14             	add    $0x14,%esp
f0101977:	5e                   	pop    %esi
f0101978:	5f                   	pop    %edi
f0101979:	5d                   	pop    %ebp
f010197a:	c3                   	ret    
f010197b:	90                   	nop
f010197c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101980:	8b 04 24             	mov    (%esp),%eax
f0101983:	be 20 00 00 00       	mov    $0x20,%esi
f0101988:	89 e9                	mov    %ebp,%ecx
f010198a:	29 ee                	sub    %ebp,%esi
f010198c:	d3 e2                	shl    %cl,%edx
f010198e:	89 f1                	mov    %esi,%ecx
f0101990:	d3 e8                	shr    %cl,%eax
f0101992:	89 e9                	mov    %ebp,%ecx
f0101994:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101998:	8b 04 24             	mov    (%esp),%eax
f010199b:	09 54 24 04          	or     %edx,0x4(%esp)
f010199f:	89 fa                	mov    %edi,%edx
f01019a1:	d3 e0                	shl    %cl,%eax
f01019a3:	89 f1                	mov    %esi,%ecx
f01019a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019a9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019ad:	d3 ea                	shr    %cl,%edx
f01019af:	89 e9                	mov    %ebp,%ecx
f01019b1:	d3 e7                	shl    %cl,%edi
f01019b3:	89 f1                	mov    %esi,%ecx
f01019b5:	d3 e8                	shr    %cl,%eax
f01019b7:	89 e9                	mov    %ebp,%ecx
f01019b9:	09 f8                	or     %edi,%eax
f01019bb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019bf:	f7 74 24 04          	divl   0x4(%esp)
f01019c3:	d3 e7                	shl    %cl,%edi
f01019c5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019c9:	89 d7                	mov    %edx,%edi
f01019cb:	f7 64 24 08          	mull   0x8(%esp)
f01019cf:	39 d7                	cmp    %edx,%edi
f01019d1:	89 c1                	mov    %eax,%ecx
f01019d3:	89 14 24             	mov    %edx,(%esp)
f01019d6:	72 2c                	jb     f0101a04 <__umoddi3+0x134>
f01019d8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019dc:	72 22                	jb     f0101a00 <__umoddi3+0x130>
f01019de:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019e2:	29 c8                	sub    %ecx,%eax
f01019e4:	19 d7                	sbb    %edx,%edi
f01019e6:	89 e9                	mov    %ebp,%ecx
f01019e8:	89 fa                	mov    %edi,%edx
f01019ea:	d3 e8                	shr    %cl,%eax
f01019ec:	89 f1                	mov    %esi,%ecx
f01019ee:	d3 e2                	shl    %cl,%edx
f01019f0:	89 e9                	mov    %ebp,%ecx
f01019f2:	d3 ef                	shr    %cl,%edi
f01019f4:	09 d0                	or     %edx,%eax
f01019f6:	89 fa                	mov    %edi,%edx
f01019f8:	83 c4 14             	add    $0x14,%esp
f01019fb:	5e                   	pop    %esi
f01019fc:	5f                   	pop    %edi
f01019fd:	5d                   	pop    %ebp
f01019fe:	c3                   	ret    
f01019ff:	90                   	nop
f0101a00:	39 d7                	cmp    %edx,%edi
f0101a02:	75 da                	jne    f01019de <__umoddi3+0x10e>
f0101a04:	8b 14 24             	mov    (%esp),%edx
f0101a07:	89 c1                	mov    %eax,%ecx
f0101a09:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a0d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a11:	eb cb                	jmp    f01019de <__umoddi3+0x10e>
f0101a13:	90                   	nop
f0101a14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a1c:	0f 82 0f ff ff ff    	jb     f0101931 <__umoddi3+0x61>
f0101a22:	e9 1a ff ff ff       	jmp    f0101941 <__umoddi3+0x71>
