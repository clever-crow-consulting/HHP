def make_global():
    global x
    x = 1

def some_func():
    print x,

def main():
    make_global()
    some_func()
    x = 2
    some_func()
    global x
    x = 3
    some_func()
    
if __name__ == "__main__":
    main()