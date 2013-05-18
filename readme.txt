smssend.lua - Утилита отправки SMS сообщений из командной строки. Использует API сервиса http://sms.ru/
Написана на Lua.
Автор Denis Saymon21 Khabarov
Email saymon@hub21.ru
Лицензия GNU GPLv3
Текущая версия: 0.3
Репозиторий: https://bitbucket.org/Saymon21/smssend.lua

Аргументы:

--help	Показывает справку по использованию.
--apiid	Устанавливает API-ID. Посмотреть его можно в разделе "Программистам" авторизировавшись на сервисе http://sms.ru
--to	Номер, куда отправлять SMS сообщение. Например 79050000000
--message Не читать стандартный поток ввода. Вместо этого будет отправлено сообщение, которое указано в данном аргументе.
--from	Имя отправителя. Должно быть согласовано с администрацией сервиса http://sms.ru
--time	Время отправки сообщения в UNIX-TIME.

Возвращаемые коды:

0	Сообщение отправлено успешно.
1 	Сервис вернул ошибку
2	HTTP ошибка
3	Ошибка при использовании утилиты


API-ID может быть прочитан из файлов:
Linux: $HOME/.smssendrc
Windows: %USERPROFILE%/.smssendrc
При использовании .smssendrc в Linux рекомендуется выполнить chmod 600 ~/.smssendrc

Пример использования:

echo "Hello world" | smssend --api-id=yourapiid --to=target_phone_number

Внимание, это бета-версия! Мы рекомендуем использовать Python версию: 
https://github.com/saymon21root/smssend
https://bitbucket.org/Saymon21/smssend
