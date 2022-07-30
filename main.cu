#include <iostream>
#include <math.h>
#include <string>
#include <fstream>
#include <sstream>

void read_pgm_file(std::string filename, int* image, int* new_image);
void write_pgm_file(std::string filename, int* new_image);
bool isNumber(char number[]);

__global__
void filter(int* image, int* new_image)
{
    int gaussian_kernel[9][9] = {
        {0, 0, 3,   2,   2,   2, 3, 0, 0},
        {0, 2, 3,   5,   5,   5, 3, 2, 0},
        {3, 3, 5,   3,   0,   3, 5, 3, 3},
        {2, 5, 3, -12, -23, -12, 3, 5, 2},
        {2, 5, 0, -23, -40, -23, 0, 5, 2},
        {2, 5, 3, -12, -23, -12, 3, 5, 2},
        {3, 3, 5,   3,   0,   3, 5, 3, 3},
        {0, 2, 3,   5,   5,   5, 3, 2, 0},
        {0, 0, 3,   2,   2,   2, 3, 0, 0},
    };

    size_t max_pixels = 65536 / (blockDim.x * gridDim.x);
    size_t index = (blockIdx.x * blockDim.x + threadIdx.x) * max_pixels;

    for (int i = index; i < index + max_pixels && index < 65536; i++)
    {
        // Convert 1D array of pixel to get 2D coordinate.
        size_t pixel_x = i % 256;
        size_t pixel_y = i / 256;
        int new_pixel_val = 0;

        for (size_t row = 0; row < 9; row++)
        {
            for (size_t col = 0; col < 9; col++)
            {
                // Subtract 4 to center the gaussian filter on the pixel.
                int mapped_gauss_x = pixel_x + col - 4;
                int mapped_gauss_y = pixel_y + row - 4; 

                size_t gauss_idx = mapped_gauss_x + 256 * mapped_gauss_y;

                if (mapped_gauss_x >= 0 && mapped_gauss_x <= 255 && mapped_gauss_y >= 0 && mapped_gauss_y <= 255)
                {
                    new_pixel_val += gaussian_kernel[col][row] * image[gauss_idx];
                }
            }
        }

        if (new_pixel_val > 255)
        {
            new_pixel_val = 255;
        }

        if (new_pixel_val < 0)
        {
            new_pixel_val = 0;
        }
        
        new_image[i] = new_pixel_val;
    }
}

int main(int argc, char *argv[])
{
    const size_t N = 256 * 256; // 1M elements
    int *image;
    int *new_image;

    if (argc != 3 || !isNumber(argv[1]) || !isNumber(argv[2]) || 65536 % (atoi(argv[1]) * atoi(argv[2])) != 0)
    {
        std::cout << "Usage:\n\n./main.exe <#Blocks> <#Threads>\n\nRequired: 65536 % (#Blocks * #Threads) == 0\n" << std::endl;
        exit(0);
    }

    int number_of_blocks = atoi(argv[1]);
    int number_of_threads = atoi(argv[2]);

    cudaMallocManaged(&image, N * sizeof(int));
    cudaMallocManaged(&new_image, N * sizeof(int));

    read_pgm_file("pepper.ascii.pgm", image, new_image);

    // Performance varies depending on total # threads.
    // Try running nvprof ./main.exe using different combinations
    // of blocks and threads to see the performance difference.
    filter<<<number_of_blocks, number_of_threads>>>(image, new_image);

    cudaDeviceSynchronize();
    write_pgm_file("output.pgm", new_image);

    // Free memory
    cudaFree(image);
    cudaFree(new_image);

    return 0;
}

void read_pgm_file(std::string filename, int* image, int* new_image)
{
    std::ifstream file;
    file.open(filename);

    int line_count = 0;
    int index = 0;
    std::string line;
    while (std::getline(file, line))
    {
        // Read every line past the first 4 lines.
        if (line_count > 3)
        {
            int pixel_val;
            std::stringstream line_stream(line);

            // Read in integer values of PGM file to image array.
            while (line_stream >> pixel_val)
            {
                image[index] = pixel_val;
                new_image[index] = 0;
                index++;
            }
        }
        else
        {
            line_count++;
        }
    }

    file.close();
}

void write_pgm_file(std::string filename, int* new_image)
{
    std::ofstream output_file;
    output_file.open(filename);

    // Start with header info.
    std::string new_file = "P2 \n256 256 \n255\n";

    // Write 17 pixel values per line.
    for (size_t i = 0; i < 65536; i++)
    {
        if (i % 17 == 0 && i != 0)
        {
            new_file += "\n";
        }

        new_file += std::to_string(new_image[i]);

        if ((i + 1) % 17 != 0)
        {
            new_file += " ";
        }
    }

    new_file += "\n";

    output_file << new_file;
    output_file.close();
}

// Used to check input arguments are numbers.
bool isNumber(char number[])
{
    int i = 0;

    //checking for negative numbers
    if (number[0] == '-')
        i = 1;
    for (; number[i] != 0; i++)
    {
        //if (number[i] > '9' || number[i] < '0')
        if (!isdigit(number[i]))
            return false;
    }
    return true;
}
