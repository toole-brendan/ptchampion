import { MetricCard } from "@/components/ui/metric-card";
import { Activity, Clock, Users } from "lucide-react";
import type { Meta, StoryObj } from "@storybook/react";

const meta = {
  title: "Components/MetricCard",
  component: MetricCard,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
} satisfies Meta<typeof MetricCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    title: "Total Users",
    value: 14298,
    withCorners: true,
    cornerStyle: "always"
  },
};

export const WithIcon: Story = {
  args: {
    title: "Active Sessions",
    value: 42,
    icon: Activity,
    withCorners: true,
    cornerStyle: "always"
  },
};

export const WithUnit: Story = {
  args: {
    title: "Average Session",
    value: 24,
    unit: "min",
    icon: Clock,
    withCorners: true,
    cornerStyle: "hover"
  },
};

export const WithDescription: Story = {
  args: {
    title: "Total Users",
    value: 3720,
    description: "25% new users this month",
    icon: Users,
    withCorners: true,
    cornerStyle: "hover"
  },
};

export const WithTrend: Story = {
  args: {
    title: "Conversion Rate",
    value: 12.8,
    unit: "%",
    change: 2.3,
    trend: "up",
    withCorners: true,
    cornerStyle: "always"
  },
};

export const NegativeTrend: Story = {
  args: {
    title: "Churn Rate",
    value: 4.6,
    unit: "%",
    change: -1.2,
    trend: "down",
    withCorners: true,
    cornerStyle: "always"
  },
}; 