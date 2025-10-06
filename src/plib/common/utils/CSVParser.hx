package plib.common.utils;

class CSVParser
{
	public static function parse(input:String):Array<Array<String>>
	{
		var rows:Array<Array<String>> = [];
		var row:Array<String> = [];
		var sb:StringBuf = new StringBuf();
		var inQuotes:Bool = false;
		var i = 0;
		var len = input.length;
		var currentChar:String = "";
		var prevChar:String = "";

		while (i <= len)
		{
			currentChar = (i < len) ? input.charAt(i) : "";

			// end of input or line
			if (currentChar == "\n" || currentChar == "")
			{
				row.push(sb.toString());
				sb = new StringBuf();
				rows.push(row);
				row = [];
				i++;
				continue;
			}
			// handle carriage return before \n (Windows)
			if (currentChar == "\r")
			{
				i++;
				continue;
			}

			if (currentChar == "\"")
			{
				if (!inQuotes)
				{
					inQuotes = true;
				}
				else
				{
					// check if next is also in quote -> escaped quote
					if (i + 1 < len && input.charAt(i + 1) == "\"")
					{
						sb.addChar('"'.code);
						i++;
					}
					else
					{
						inQuotes = false;
					}
				}
			}
			else if (currentChar == "," && !inQuotes)
			{
				row.push(sb.toString());
				sb = new StringBuf();
			}
			else
			{
				if (currentChar != "")
				{
					sb.addChar(currentChar.charCodeAt(0));
				}
			}

			i++;
		}

		// add trailing row if file doesnt end with newline
		if (sb.length > 0 || row.length > 0)
		{
			row.push(sb.toString());
			rows.push(row);
		}

		return rows;
	}
}
