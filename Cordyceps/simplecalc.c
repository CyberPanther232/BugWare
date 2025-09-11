#include <stdio.h>

int main() {
    char op;
    double first, second;

    // Ask the user to enter an operator
    printf("Enter an operator (+, -, *, /): ");
    scanf("%c", &op);

    // Ask the user to enter two operands
    printf("Enter two operands: ");
    scanf("%lf %lf", &first, &second);

    // Use a switch statement to perform the correct operation
    switch (op) {
        case '+':
            printf("%.1lf + %.1lf = %.1lf\n", first, second, first + second);
            break;
        case '-':
            printf("%.1lf - %.1lf = %.1lf\n", first, second, first - second);
            break;
        case '*':
            printf("%.1lf * %.1lf = %.1lf\n", first, second, first * second);
            break;
        case '/':
            // Check if the divisor is zero
            if (second != 0.0) {
                printf("%.1lf / %.1lf = %.1lf\n", first, second, first / second);
            } else {
                printf("Error! Division by zero is not allowed.\n");
            }
            break;
        // If the operator doesn't match any case
        default:
            printf("Error! Operator is not correct\n");
    }

    return 0;
}
