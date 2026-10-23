const TITLES={overview:"نمای کلی",architecture:"معماری سیستم",roadmap:"نقشه راه",history:"تاریخچه تغییرات",sources:"منابع و فایل‌ها"};
const ENTRIES=[
["H010","بهینه‌سازی CI","محدود کردن اجرای تست سنگین به تغییرات SQL، اسکریپت و تنظیمات اجرایی؛ ثبت آخرین نتیجه موفق.","تست موفق"],
["H009","آزمایشگاه PostgreSQL محلی","Docker Compose برای تست دیتابیس بدون سرور اصلی و بدون اتصال به Remnawave.","آماده"],
["H008","وابستگی‌های استقرار","ثبت نیاز به VPS، دامنه، اتصال پرداخت و تست واقعی شبکه قبل از اعلام Production.","در انتظار"],
["H007","قفل نسخه منابع","ثبت Commit SHA پروژه‌های مرجع و اسکریپت بررسی نسخه‌های منبع.","آماده"],
["H006","قرارداد معماری و n8n","تعیین مرزهای Control Plane، Data Plane، پرداخت، مدیریت کاربران و خطاها.","مستند"],
["H005","کنترل ظرفیت ۵۰۰ کاربر","Migration و تست PostgreSQL با محدودیت تراکنشی، جلوگیری از تکرار و رقابت هم‌زمان.","تست موفق"],
["H004","فعالیت‌های پیش از سرور","تعیین کارهای قابل انجام بدون VPS: دیتابیس آزمایشی، اتوماسیون و آزمایش‌ها.","برنامه‌ریزی"],
["H003","ساخت فضای GitHub","ایجاد v2ray-500 به‌صورت مستقل در Repository موجود و ثبت مستندات اولیه.","انجام‌شده"],
["H002","انتخاب پروژه‌های Open Source","بررسی Remnawave Backend/Node، Bedolaga و RemnaSetup.","انجام‌شده"],
["H001","تعریف محدوده کسب‌وکار","سقف ۵۰۰ اشتراک فعال، توسعه مرحله‌ای و بودجه ماهانه ۱۵ میلیون تومان.","تصمیم قطعی"],
];
function makeHistory(){
 const root=document.querySelector("#history-entries");
 if(!root)return;
 root.replaceChildren(...ENTRIES.map(([id,title,desc,status])=>{
  const article=document.createElement("article");article.className="history-entry";
  const code=document.createElement("span");code.className="history-code";code.textContent=id;
  const card=document.createElement("div");card.className="history-content";
  const head=document.createElement("h3");head.textContent=title;
  const p=document.createElement("p");p.textContent=desc;
  const foot=document.createElement("div");foot.className="history-meta";
  const date=document.createElement("span");date.textContent="۲۳ اکتبر ۲۰۲۶";
  const tag=document.createElement("b");tag.textContent=status;
  foot.append(date,tag);card.append(head,p,foot);article.append(code,card);return article;
 }));
}
function showSection(name){
 if(!TITLES[name])name="overview";
 document.querySelectorAll(".panel-section").forEach(el=>el.classList.toggle("current",el.id===name));
 document.querySelectorAll(".nav-link").forEach(el=>{
   const active=el.dataset.nav===name;
   el.classList.toggle("active",active);
   if(active)el.setAttribute("aria-current","page");else el.removeAttribute("aria-current");
 });
 document.querySelector("#page-label").textContent=TITLES[name];
 document.title=TITLES[name]+" | Xray-500";
 document.querySelector("#sidebar").classList.remove("open");
 window.scrollTo({top:0,behavior:"instant"});
}
document.addEventListener("DOMContentLoaded",()=>{
 makeHistory();
 const menu=document.querySelector("#menu-toggle");
 menu?.addEventListener("click",()=>document.querySelector("#sidebar").classList.toggle("open"));
 document.querySelectorAll('a[href^="#"]').forEach(a=>{
   a.addEventListener("click",e=>{
     const id=a.getAttribute("href").substring(1);
     if(!TITLES[id])return;
     e.preventDefault();
     if(window.location.hash!==("#"+id))history.pushState(null,"","#"+id);
     showSection(id);
   });
 });
 window.addEventListener("hashchange",()=>showSection(location.hash.substring(1)));
 showSection(location.hash.substring(1));
});
