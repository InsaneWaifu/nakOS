#![no_std]
#![no_main]

use core::{
    arch::asm,
    cell::UnsafeCell,
    fmt::{write, Formatter, Write},
    mem::swap,
    ops::{Deref, DerefMut},
    panic::PanicInfo,
};

use vga::print;

struct Mutex<T> {
    lock: bool,
    inner: UnsafeCell<T>,
}

impl<T> Mutex<T> {
    pub fn lock(&mut self) -> MutexGuard<T> {
        let mut lock1 = true;
        loop {
            let bl: *mut bool = &mut lock1;
            let al: *mut bool = &mut self.lock;
            unsafe {
                asm!("xchg [{x}] [{y}]", x = in(reg) al, y = in(reg) bl);
            }
            if !lock1 {
                return MutexGuard { parent: self };
            }
        }
    }
}

struct MutexGuard<'a, T> {
    parent: &'a mut Mutex<T>,
}

impl<'a, T> Drop for MutexGuard<'a, T> {
    fn drop(&mut self) {
        self.parent.lock = false;
    }
}

impl<'a, T> Deref for MutexGuard<'a, T> {
    type Target = T;
    fn deref(&self) -> &Self::Target {
        unsafe { &*self.parent.inner.get() }
    }
}

impl<'a, T> DerefMut for MutexGuard<'a, T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        unsafe { &mut *self.parent.inner.get() }
    }
}

unsafe impl<T> Send for Mutex<T> {}
unsafe impl<T> Sync for Mutex<T> {}

mod vga;
#[repr(C)]
struct ScreenChar {
    ascii_character: u8,
    color_code: u8,
}

fn black_box<T>(dummy: T) -> T {
    unsafe { core::ptr::read_volatile(&dummy) }
}

struct Con();

struct Con2();

impl Write for Con {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        print(s);
        Ok(())
    }
}

trait TestTrait {
    fn say_hello(&self);
}

impl TestTrait for Con2 {
    fn say_hello(&self) {
        print("hello2 from test");
    }
}

impl TestTrait for Con {
    fn say_hello(&self) {
        print("hello from test")
    }
}

#[inline(never)]
fn run_test(tt: &mut dyn TestTrait) {
    tt.say_hello();
}

fn main() {
    let mut con = Con {};
    let vga = 0xb8000 as *mut ScreenChar;
    let mut offset = 0;

    unsafe { asm!("xchg bx, bx") };
    let str = b"hello  rusty world";

    str.iter().for_each(|x| {
        unsafe {
            vga.offset(offset).write_volatile(ScreenChar {
                ascii_character: *x,
                color_code: 0x2f,
            })
        }
        offset += 1;
    });

    print("TEST\nTEST2\nTEST3\nTHANKYOUNAK\n");
    print("try trait\n");
    unsafe { asm!("xchg bx, bx", "xchg ax, ax") };

    write(&mut con, format_args!("hello"));
    run_test(&mut con);
    print("workd");
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    unsafe { asm!("xchg bx, bx") };
    print("panic");
    loop {
        unsafe { asm!("mov [0xb8000], {0:l}", in(reg) 78) };
    }
}

#[no_mangle]
#[inline(never)]
pub extern "C" fn _start() -> ! {
    main();

    panic!();
}
