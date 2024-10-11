#!/usr/bin/env python
import sqlite3
import sys

from pygments.lexers.sql import SqlLexer

from prompt_toolkit import PromptSession
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.lexers import PygmentsLexer
from prompt_toolkit.styles import Style

sql_completer = WordCompleter(
    [
        "create synth",
    ],
    ignore_case=True,
)

style = Style.from_dict(
    {
        "completion-menu.completion": "bg:#008888 #ffffff",
        "completion-menu.completion.current": "bg:#00aaaa #000000",
        "scrollbar.background": "bg:#88aaaa",
        "scrollbar.button": "bg:#222222",
    }
)


def main(database):
    connection = sqlite3.connect(database)
    session = PromptSession(
        lexer=PygmentsLexer(SqlLexer), completer=sql_completer, style=style
    )

    while True:
        try:
            text = session.prompt("> ")
        except KeyboardInterrupt:
            continue  # Control-C pressed. Try again.
        except EOFError:
            break  # Control-D pressed.

        with connection:
            try:
                messages = connection.execute(text)
            except Exception as e:
                print(repr(e))
            else:
                for message in messages:
                    print(message)

    print("GoodBye!")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        db = ":memory:"
    else:
        db = sys.argv[1]

    main(db)