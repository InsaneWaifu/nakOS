use core::{
    arch::asm,
    cell::UnsafeCell,
    fmt::{self, Write},
};

//use crate::Mutex;

static HELLO: &str = "TESTVGA HELLO WORLD";
static mut WIDTH: UnsafeCell<isize> = UnsafeCell::new(80);
const HEIGHT: isize = 25;

struct Console {
    line: u32,
    column: u32,
    //buf: [u8; WIDTH as usize * HEIGHT as usize],
}

/*static mut VGA_TEXT: Mutex<Console> = Mutex {
    inner: UnsafeCell::new(Console {
        line: 0,
        column: 0,
        buf: [0; WIDTH as usize * HEIGHT as usize],
    }),
    lock: false,
};*/

static mut UCONSOLE: UnsafeCell<Console> = UnsafeCell::new(Console { line: 0, column: 0 });

pub fn update_width() {
    let width = 0x1 as *mut u8;
    unsafe { *WIDTH.get() = width.read() as isize };
}

type VgaBuffer = *mut u8;

trait VgaBuf {
    fn offsetxy(&self, x: isize, y: isize) -> VgaBuffer;
    fn writec(&self, char: u8);
}

impl VgaBuf for VgaBuffer {
    #[inline(never)]

    fn offsetxy(&self, x: isize, y: isize) -> VgaBuffer {
        if y >= HEIGHT {
            panic!("{}", HELLO);
        }
        if x >= unsafe { *WIDTH.get() } {
            panic!("x out of bounds");
        }
        unsafe { self.offset(*WIDTH.get() * y + (x * 2)) }
    }
    #[inline(never)]

    fn writec(&self, char: u8) {
        unsafe {
            self.offset(0).write(char);
            self.offset(1).write(0xb);
        }
    }
}
#[inline(never)]

fn shift_screen(vga_buffer: VgaBuffer) {
    // redraw screen shifted up
    for y in 1..HEIGHT {
        for x in 0..unsafe { *WIDTH.get() } {
            unsafe {
                vga_buffer
                    .offsetxy(x, y - 1)
                    .writec(vga_buffer.offsetxy(x, y).read_volatile())
            }
        }
    }
}

fn write_str(c: &mut Console, s: &str) {
    for i in HELLO.bytes() {
        if i == 0 {
            panic!("HELO was zero");
        }
    }
    unsafe { asm!("xchg bx, bx") };
    let vga_buffer = 0xb8000 as VgaBuffer;
    for char in s.chars() {
        if char == '\n' {
            c.line += 1;
            c.column = 0;
            if c.line == 25 {
                c.line = 24;
                shift_screen(vga_buffer)
            }
        } else {
            if c.column == 80 {
                c.line += 1;
                c.column = 0;
                if c.line == 25 {
                    c.line = 24;
                    shift_screen(vga_buffer)
                }
            }
            vga_buffer
                .offsetxy(c.column as isize, c.line as isize)
                .writec(char as u8);
            c.column += 1;
        }
    }
}

#[inline(never)]
pub fn print(s: &str) {
    unsafe { write_str(&mut *UCONSOLE.get(), s) };
}
