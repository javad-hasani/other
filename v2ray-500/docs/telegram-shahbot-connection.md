# اتصال تلگرام به شاه‌پنل — ShahBot (بدون توسعه ربات تازه)

**تاریخ بررسی:** 2026-10-27  
**وضعیت:** کد و راهنمای اتصال آماده؛ هیچ توکن، وب‌هوک یا سرویس عملیاتی هنوز به حساب ما متصل نشده است.

## تصمیم

از **ShahBot داخلی شاه‌پنل** استفاده می‌کنیم، نه MirzaBot، Bedolaga یا ربات مستقل. ماژول رسمی ShahPanel در نسخه قفل‌شده `v3.38.5` با شناسه `shahbot` و مجوز AGPL-3.0-or-later وجود دارد. امکانات مستند و قابل‌بررسی سورسی آن: فروش و تمدید، سرویس آزمایشی، کیف پول، کد تخفیف، پشتیبانی، نوتیفیکیشن، مینی‌اپ و مدیریت چند ربات نماینده.

**هیچ پرداخت یا اکانت واقعی قبل از آزمون PSP، ظرفیت و Remnawave فعال نشود.**

## مشخصات عمومی ربات انتخاب‌شده

- نام کاربری اعلام‌شده توسط کاربر: **[@RavixNetBot](https://t.me/RavixNetBot)**
- مرجع غیرمحرمانه پروژه: [config/telegram-public.json](../config/telegram-public.json)
- **وضعیت:** فقط نام عمومی ثبت شده و مالکیت ربات/`getMe` از طریق Telegram Bot API هنوز تأیید نشده است؛ اتصال Webhook برقرار نشده است.

## گام ۱ — آماده‌سازی ربات در Telegram (قبل از VPS)

1. ربات اعلام‌شده **@RavixNetBot** است؛ در [@BotFather](https://t.me/BotFather) از دستور `/mybots` بررسی کن که واقعاً در فهرست ربات‌های تحت مدیریتت باشد. اگر نیست، قبل از هر عملیات اتصال، مالکیت و نام درست را روشن کن. برای ربات موجود، `/newbot` لازم نیست.
2. BotFather یک **توکن محرمانه** می‌دهد. آن را فقط در Password Manager شخصی نگه دار؛ در ChatGPT، GitHub عمومی، فایل HISTORY، اسکرین‌شات، URL یا چت گروهی قرار نده. اگر قبلاً جایی افشا شده، در BotFather **توکن را عوض کن**.
3. پیام‌رسانی از طریق `/start` را از حساب ادمین با ربات آغاز کن. برای ارسال پیام آزمایشی از ShahBot، باید `admin_chat_ids` حاوی ID عددی همین چت باشد. ID را در محیط امن خودت از Telegram Bot API `getUpdates` **قبل از تنظیم Webhook** یا ابزار داخلی مورد اعتماد بگیر. `getUpdates` در حضور Webhook فعال کار نمی‌کند؛ برای ربات در حال استفاده Webhook را کورکورانه حذف نکن.
4. **فعلاً BotFather را به هیچ سیستم قدیمی متصل نکن.** یک ربات فقط یک Webhook فعال دارد؛ توکن ربات Ravix یا هر پروژه دیگر را بدون تصمیم رسمی برای شاه‌پنل مصرف نکن.

## گام ۲ — پیش‌نیاز اتصال واقعی (پس از نصب شاه‌پنل)

- ShahPanel با HTTPS معتبر و `APP_URL=https://<panel-domain>` درست و قابل‌دسترسی از Telegram نصب شده باشد. Telegram Bot API Webhook نیازمند URL عمومی HTTPS است؛ پورت‌های پشتیبانی‌شده 443، 80، 88 و 8443 هستند. برای محیط عملیاتی ترجیحاً پورت 443.
- MariaDB/MySQL شاه‌پنل، migrations ماژول ShahBot و حقوق مدیر تأیید شوند. در `modules/shahbot/module.json` شناسه و نام آن مشخص است.
- در پنل، ماژول **ربات فروش تلگرام شاه‌پنل / ShahBot** فعال و صفحه **ادمین → ShahBot → تنظیمات → اتصال** در دسترس باشد. آدرس داخلی طبق سورس `/{admin_path}/shahbot/settings?tab=connection` است؛ مسیر ادمین می‌تواند تغییر کند.
- در تب اتصال، مقادیر **توکن ربات**، **مالک فروش** (`owner_user_id`: یک کاربر agent یا seller واقعی داخل ShahPanel)، **شناسه‌های چت ادمین**، `mode=webhook` و **پروکسی** در صورت نیاز به خروجی `api.telegram.org` تعریف شوند.
- ابتدا **ذخیره** و سپس از فرم داخلی **اتصال به تلگرام** استفاده کن. ShahBot خودش `getMe`، `setWebhook` و پیام آزمایشی `sendMessage` را اجرا می‌کند؛ درخواست دستی یا کد جدید برای ثبت Webhook لازم نیست.

## گام ۳ — راه‌اندازی ایمن بدون فروش واقعی

در تنظیمات ShahBot **فروش (`sales_enabled`) را غیرفعال** کن، چون مقدار پیش‌فرض داخل سورس `1` است. همچنین آزمایش (`test_enabled=0`) و شارژ کیف پول (`topup_enabled=0`) را برای زمان آماده‌سازی خاموش نگه دار. ارائه روش پرداخت و فروش در پنل اصلی و ربات را هم تا تأیید حساب PSP، ثبت پرداخت غیرتکراری و محدودیت ۵۰۰ نفر غیرفعال نگه دار. صرف خاموش کردن یک کلید ممکن است همه مسیرهای دسترسی را مسدود نکند؛ قبل از بازکردن ربات برای مشتریان آزمون انجام بده.

**تفاوت دو تنظیم:** `owner_user_id` شناسه یکی از کاربران agent/seller در خود ShahPanel است؛ `admin_chat_ids` شناسه عددی چت تلگرام مسئول ارسال تست و هشدار است. آن‌ها را اشتباه نگیر.

## گام ۴ — تست و معیار پذیرش

1. `getMe` از طریق دکمه اتصال شاه‌پنل موفق و username شناسایی شود.
2. `getWebhookInfo` نشان دهد `url` با `APP_URL` شاه‌پنل منطبق است و خطای ارسال وجود ندارد.
3. ادمین قبلاً `/start` را زده باشد، سپس پیام آزمایشی به ID عددی ادمین برسد.
4. از تلگرام پیام `/start` بفرست و منوی فارسی را دریافت کن؛ callback_query ها با پاسخ 2xx پردازش شوند.
5. درخواست ساختگی به `/shahbot/webhook/{secret}` **بدون** هدر `X-Telegram-Bot-Api-Secret-Token` رد شود. خود سورس مسیر را با همین هدر محافظت می‌کند؛ نباید در شبکه عمومی توکن/secret لاگ شود.
6. کاربر عادی نتواند گزینه ادمین یا سفارشِ بدون پرداخت تأییدشده را اجرا کند.
7. `sales_enabled=0` و `test_enabled=0` از مسیر ربات/مینی‌اپ آزمایش شوند. خرید واقعی همچنان مسدود بماند.
8. اکانت حقیقی و فروش تنها پس از تست تمام چرخه مالی ShahPanel و اتصال Remnawave و کنترل سقف فعال ۵۰۰ کاربر مجاز شود.

## نکات کد و خطاهای متداول

- وب‌هوک ShahBot: `POST /shahbot/webhook/{secret}`. مقدار `{secret}` **از تنظیمات شاه‌پنل تولید می‌شود**؛ نمونه عمومی نباید با توکن واقعی پر شود.
- در `WebhookService.php` ثبت Webhook از روی `APP_URL` ساخته می‌شود و Telegram `secret_token` را برای هدر امنیتی می‌فرستد. **اولین اتصال** `drop_pending_updates=true` می‌دهد؛ بنابراین روی ربات فعال و پرمشتری از روی عادت دکمه اتصال را تکرار نکن.
- `TelegramClient.php` امکان proxy با آدرس `http://` یا `socks5://` را دارد. اگر دسترسی خروجی هاست به Telegram API مسدود است، باید در فضای عملیاتی مستقل و امن مسیر ارتباطی برقرار شود؛ اطلاعات proxy را وارد Git نکن.
- اگر `getMe` خطای 401 می‌دهد: توکن اشتباه/ابطال‌شده است. اگر `setWebhook` خطا می‌دهد: HTTPS، `APP_URL` و دسترسی URL عمومی را بررسی کن. اگر پیام آزمایشی به `chat not found` خورد: ادمین `/start` بزند و `admin_chat_ids` را بررسی کن.
- Telegram از یک Bot token در یک اتصال فعلی استفاده می‌کند. اتصال به سرویس قدیمی را بدون هماهنگی قطع نکن.

## محل‌های منبع در ShahPanel v3.38.5

- [modules/shahbot/module.json](https://github.com/shahinst/shahpanel/blob/v3.38.5/modules/shahbot/module.json)
- [SettingsController.php](https://github.com/shahinst/shahpanel/blob/v3.38.5/modules/shahbot/src/Http/Controllers/Admin/SettingsController.php)
- [settings.blade.php](https://github.com/shahinst/shahpanel/blob/v3.38.5/modules/shahbot/resources/views/shahbot/settings.blade.php)
- [WebhookService.php](https://github.com/shahinst/shahpanel/blob/v3.38.5/modules/shahbot/src/Services/WebhookService.php)
- [WebhookController.php](https://github.com/shahinst/shahpanel/blob/v3.38.5/modules/shahbot/src/Http/Controllers/WebhookController.php)
- [Official Telegram Bot API](https://core.telegram.org/bots/api)

## هنوز انجام نشده

- [x] آدرس عمومی `@RavixNetBot` از کاربر دریافت و در GitHub ثبت شده است
- [ ] مالکیت و اتصال واقعی ربات با `getMe` تأیید شود (هنوز انجام نشده)
- [ ] دریافت و نگهداری امن توکن در فضای مدیر
- [ ] آماده‌شدن ShahPanel + HTTPS + سرور مستقل
- [ ] ساخت ادمین/agent/seller و تعیین مالک ربات
- [ ] ثبت token و admin chat IDs در فرم خود شاه‌پنل
- [ ] فعال‌شدن Webhook و دریافت اولین پیام آزمون
- [ ] تست امنیت، ظرفیت و پرداخت پیش از فروش عمومی

**این سند راهنماست، نه شاهد اتصال انجام‌شده. هیچ Token/Webhook/API در این مرحله ساخته یا ثبت نشده است.**
