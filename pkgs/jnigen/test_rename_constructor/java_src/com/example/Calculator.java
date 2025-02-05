public class Calculator {
    int a;
    int b;
    public Calculator(int a) {
        this.a = a;
        b = 10;
        System.out.println("Constructor called with " + a);
    }

    public Calculator() {
        a = 10;
        b = 10;
        System.out.println("Constructor called with no args");
    }

    public Calculator(int a, int b) {
        this.a = a;
        this.b = b;
        System.out.println("Constructor called with " + a + " and " + b);
    }

    public int add(int a, int b) {
        return a + b + this.a + this.b;
    }
}
