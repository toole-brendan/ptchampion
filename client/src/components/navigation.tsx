import { Link } from "wouter";
import { Home, BookmarkIcon, User, Settings } from "lucide-react";

interface NavigationProps {
  active: "home" | "history" | "profile" | "settings";
}

export default function Navigation({ active }: NavigationProps) {
  return (
    <nav className="bg-white border-t border-slate-200 fixed bottom-0 left-0 right-0">
      <div className="container mx-auto px-4">
        <div className="flex justify-around">
          <Link href="/" className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "home" ? "text-primary" : "text-gray-700"}`}>
            <Home className="w-6 h-6 mb-1" />
            <span>Home</span>
          </Link>
          <Link href="/history" className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "history" ? "text-primary" : "text-gray-700"}`}>
            <BookmarkIcon className="w-6 h-6 mb-1" />
            <span>History</span>
          </Link>
          <Link href="/profile" className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "profile" ? "text-primary" : "text-gray-700"}`}>
            <User className="w-6 h-6 mb-1" />
            <span>Profile</span>
          </Link>
          <Link href="/profile" className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "settings" ? "text-primary" : "text-gray-700"}`}>
            <Settings className="w-6 h-6 mb-1" />
            <span>Settings</span>
          </Link>
        </div>
      </div>
    </nav>
  );
}
