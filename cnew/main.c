#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/wait.h>

#define MAX_PATH_LENGTH 4096
#define MAX_PROJECT_NAME_LENGTH 255

/* Content of the files that cnew will generate */
const char *MAIN_C_CONTENT =
	"#include <stdio.h>\n"
	"\n"
	"int main(void)\n"
	"{\n"
	"\tprintf(\"Hello, World!\\n\");\n"
	"\treturn 0;\n"
	"}\n";

/* Makefile commands must start with a TAB, so \t is used here */
const char *MAKEFILE_CONTENT =
	"CC = gcc\n"
	"CFLAGS = -Wall -Wextra -Iinclude\n"
	"TARGET = program\n"
	"SRC = $(wildcard src/*.c)\n"
	"OBJ = $(SRC:.c=.o)\n"
	"\n"
	"all: $(TARGET)\n"
	"\n"
	"$(TARGET): $(OBJ)\n"
	"\t$(CC) $(OBJ) -o $(TARGET)\n"
	"\n"
	"src/%.o: src/%.c\n"
	"\t$(CC) $(CFLAGS) -c $< -o $@\n"
	"\n"
	"clean:\n"
	"\trm -f $(OBJ) $(TARGET)\n"
	"\n"
	".PHONY: all clean\n";

const char *GITIGNORE_CONTENT =
	"*.o\n"
	"program\n";

int is_valid_project_name(const char *project_name)
{
	size_t name_length = strlen(project_name);

	if (name_length == 0 || name_length > MAX_PROJECT_NAME_LENGTH)
	{
		return 0;
	}

	for (size_t index = 0; index < name_length; index++)
	{
		unsigned char current_char = (unsigned char)project_name[index];
		/* only letters, digits and '-' are allowed */
		if (!isalnum(current_char) && current_char != '-')
		{
			return 0;
		}
	}
	return 1;
}

int path_exists(const char *path)
{
	struct stat path_info;
	return stat(path, &path_info) == 0;
}

int is_git_installed(void)
{
	/* same idea as "command -v" dependency check in setup.sh */
	int command_status = system("command -v git > /dev/null 2>&1");
	return command_status != -1 && WIFEXITED(command_status) && WEXITSTATUS(command_status) == 0;
}

int create_directory(const char *dir_path)
{
	if (mkdir(dir_path, 0755) != 0)
	{
		printf("Error: Cannot create directory %s (%s)\n", dir_path, strerror(errno));
		return -1;
	}
	return 0;
}

int create_file_with_content(const char *file_path, const char *content)
{
	FILE *file_pointer = fopen(file_path, "w");

	if (file_pointer == NULL)
	{
		printf("Error: Cannot create file %s (%s)\n", file_path, strerror(errno));
		return -1;
	}

	fputs(content, file_pointer);

	if (fclose(file_pointer) != 0)
	{
		printf("Error: Cannot write to file %s\n", file_path);
		return -1;
	}
	return 0;
}

int init_git_repository(const char *project_name)
{
	char git_command[MAX_PATH_LENGTH];

	/* project_name is already validated, so it is safe to put into a shell command */
	snprintf(git_command, sizeof(git_command), "git init -q \"./%s\" > /dev/null 2>&1", project_name);

	int command_status = system(git_command);
	if (command_status == -1 || !WIFEXITED(command_status) || WEXITSTATUS(command_status) != 0)
	{
		printf("Error: Failed to initialize Git repository\n");
		return -1;
	}
	return 0;
}

int create_project(const char *project_name, int with_git)
{
	char src_dir_path[MAX_PATH_LENGTH];
	char include_dir_path[MAX_PATH_LENGTH];
	char main_c_path[MAX_PATH_LENGTH];
	char makefile_path[MAX_PATH_LENGTH];
	char readme_path[MAX_PATH_LENGTH];
	char gitignore_path[MAX_PATH_LENGTH];
	char readme_content[MAX_PATH_LENGTH];

	if (!is_valid_project_name(project_name))
	{
		printf("Error: %s is not a valid project name\n", project_name);
		printf("Note: Only letters, digits and '-' are allowed (no space)\n");
		return 1;
	}

	if (path_exists(project_name))
	{
		printf("Error: %s already exists\n", project_name);
		return 1;
	}

	/* check git first, so nothing is created if git is missing */
	if (with_git && !is_git_installed())
	{
		printf("Error: Git is not installed. Please install Git and try again\n");
		return 1;
	}

	snprintf(src_dir_path, sizeof(src_dir_path), "%s/src", project_name);
	snprintf(include_dir_path, sizeof(include_dir_path), "%s/include", project_name);
	snprintf(main_c_path, sizeof(main_c_path), "%s/src/main.c", project_name);
	snprintf(makefile_path, sizeof(makefile_path), "%s/Makefile", project_name);
	snprintf(readme_path, sizeof(readme_path), "%s/README.md", project_name);
	snprintf(gitignore_path, sizeof(gitignore_path), "%s/.gitignore", project_name);
	snprintf(readme_content, sizeof(readme_content), "# %s\n", project_name);

	if (create_directory(project_name) != 0 ||
		create_directory(src_dir_path) != 0 ||
		create_directory(include_dir_path) != 0)
	{
		return 1;
	}

	if (create_file_with_content(main_c_path, MAIN_C_CONTENT) != 0 ||
		create_file_with_content(makefile_path, MAKEFILE_CONTENT) != 0 ||
		create_file_with_content(readme_path, readme_content) != 0)
	{
		return 1;
	}

	if (with_git)
	{
		if (init_git_repository(project_name) != 0 ||
			create_file_with_content(gitignore_path, GITIGNORE_CONTENT) != 0)
		{
			return 1;
		}
		printf("Initialized Git repository in %s\n", project_name);
	}

	printf("Created project %s\n", project_name);
	return 0;
}

void show_usage(void)
{
	printf("These are the action to use the system:\n");
	printf("-------------------------------------------------------------------------------\n");
	printf("| --name <project-name>               | create a new C project folder.        |\n");
	printf("| --name <project-name> --with-git    | create the project and init Git repo. |\n");
	printf("| --help                              | show this help.                       |\n");
	printf("-------------------------------------------------------------------------------\n");
	printf("| Project name only accepts letters, digits and '-' (no space).               |\n");
	printf("-------------------------------------------------------------------------------\n");
}

int main(int argc, char *argv[])
{
	if (argc >= 2 && strcmp(argv[1], "--help") == 0)
	{
		show_usage();
		return 0;
	}
	else if (argc >= 2 && strcmp(argv[1], "--name") == 0)
	{
		const char *project_name = NULL;
		const char *extra_option = NULL;

		if (argc >= 3)
		{
			project_name = argv[2];
		}
		if (argc >= 4)
		{
			extra_option = argv[3];
		}

		if (project_name == NULL || strncmp(project_name, "--", 2) == 0)
		{
			printf("Error: Project name is required. Ex: cnew --name my-project\n");
			return 1;
		}
		else if (argc > 4 || (extra_option != NULL && strcmp(extra_option, "--with-git") != 0))
		{
			printf("Error: Unknown option %s\n", extra_option);
			return 1;
		}
		else
		{
			int with_git = (extra_option != NULL);
			return create_project(project_name, with_git);
		}
	}
	else
	{
		show_usage();
		return 1;
	}
}
