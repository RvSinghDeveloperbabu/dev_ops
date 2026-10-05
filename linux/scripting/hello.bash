
echo > out.log; echo > error.log

echo "First bash script"

name="Ravi Kumar"

echo "My name is $name"


echo "Using the if condition to check if the files exists or not"

error_file="./error.log"
output_file="./output.log"

if [-f"$error_file"]; then
    echo "Error file exists"
else
    echo "Error file does not exist"
fi

if [-f"$output_file"]; then
    echo "Output file exists"
else
    echo "Output file does not exist"
fi