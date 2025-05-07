return {
  setup = function()
    require('code_runner').setup({
      focus = false,
      term = {
        position = "bot",
        size = 12,
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      },
      filetype = {
        -- Basic languages
        python = "python3 -u $file",
        javascript = "node $file",
        typescript = "deno run $file",
        rust = "cd $dir && cargo run",

        -- C/C++
        c = "cd $dir && gcc $file -o $fileBasenameNoExtension && $dir/$fileBasenameNoExtension",
        cpp = "cd $dir && g++ $file -o $fileBasenameNoExtension && $dir/$fileBasenameNoExtension",

        -- JVM languages
        java = "cd $dir && javac $file && java $fileBasenameNoExtension",
        kotlin = "cd $dir && kotlinc $file -include-runtime -d $fileBasenameNoExtension.jar && java -jar $fileBasenameNoExtension.jar",

        -- Scripting
        sh = "bash $file",
        lua = "lua $file",
        perl = "perl $file",
        php = "php $file",
        r = "Rscript $file",

        -- Functional languages
        haskell = "runhaskell $file",

        -- Other compiled languages
        go = "go run $file",
        fortran = "gfortran $file -o $fileBasenameNoExtension && $dir/$fileBasenameNoExtension",
        cs = "cd $dir && dotnet run",
      },

      project = {
        -- Rails projects
        ["~/projects/rails"] = {
          name = "Rails",
          command = "cd $dir && bin/rails server"
        },
        -- Django projects
        ["~/projects/django"] = {
          name = "Django",
          command = "cd $dir && python manage.py runserver"
        },
      }
    })
  end
}
