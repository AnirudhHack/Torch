import Link from "next/link"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export function Landing() {
  return (
    <main className="flex-1">
      <section className="flex justify-center w-full py-12 md:py-24 lg:py-32">
        <div className="container px-4 md:px-6">
          <div className="grid gap-6 lg:grid-cols-[1fr_400px] lg:gap-12 xl:grid-cols-[1fr_600px]">
            <div className="flex flex-col justify-center space-y-4">
              <div className="space-y-2">
                <h1 className="text-3xl font-bold tracking-tighter sm:text-5xl xl:text-6xl/none">
                  Supercharge Your sUSDe Yields
                </h1>
                <p className="max-w-[600px] text-muted-foreground md:text-xl">
                  Turn your 29% sUSDe yield into up to <span className="text-primary font-bold">81% APY</span> through leverage
                </p>
              </div>
              <div className="flex flex-col gap-2 min-[400px]:flex-row">
                <Link
                  href="/vault"
                  className="inline-flex h-10 items-center justify-center rounded-md bg-primary px-8 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"
                  prefetch={false}>
                  Start Earning
                </Link>
              </div>
            </div>
            <img
              src="/ethena.png"
                alt="Hero"
                className="mx-auto w-[400px] h-[400px] overflow-hidden rounded-xl object-bottom " />
          </div>
        </div>
      </section>
    </main>
  );
}