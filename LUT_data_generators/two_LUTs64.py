with open("tanh_data64.mem", "r") as f:
    lines = f.readlines()

# podzielenie lini na parzyste i nieparzyste
with open("tanh_even64.mem", "w") as f_even, open("tanh_odd64.mem", "w") as f_odd:
    for i, line in enumerate(lines):
        if i % 2 == 0:
            f_even.write(line)
        else:
            f_odd.write(line)